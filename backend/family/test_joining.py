from datetime import timedelta
from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.core.files.uploadedfile import SimpleUploadedFile
from django.db.models import ProtectedError
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from .models import FamilyTree, Person, Relationship, TreeMembership, FamilyInvitation, JoinRequest, RecordChange
import json
from concurrent.futures import ThreadPoolExecutor
from threading import Barrier
from unittest import skipUnless
from django.db import connection, connections, close_old_connections
from django.test import TransactionTestCase
from rest_framework.exceptions import ValidationError


class FamilyJoiningTests(TestCase):
    def setUp(self):
        cache.clear()
        User = get_user_model()
        self.owner = User.objects.create_user(username='join-owner', email='owner@join.test')
        self.user = User.objects.create_user(username='anna', email='anna@join.test', first_name='Anna', last_name='Family')
        self.other = User.objects.create_user(username='stranger', email='stranger@join.test', first_name='Other', last_name='Family')
        self.tree = FamilyTree.objects.create(name='Private family', owner=self.owner)
        self.gp = Person.objects.create(family_tree=self.tree, first_name='Mariam', last_name='Family', gender='F')
        self.parent = Person.objects.create(family_tree=self.tree, first_name='Paul', last_name='Family', gender='O')
        self.person = Person.objects.create(family_tree=self.tree, first_name='Anna', last_name='Family', gender='F', biography='Keep me')
        self.gp_link = Relationship.objects.create(person1=self.gp, person2=self.parent, relationship_type='PARENT')
        self.child_link = Relationship.objects.create(person1=self.parent, person2=self.person, relationship_type='PARENT')
        self.client = APIClient()

    def command(self, user, action, **data):
        self.client.force_authenticate(user)
        return self.client.post('/api/family-access/', {'action': action, **data}, format='json')

    def invite(self, mode='EXISTING', anchor=None, **extra):
        response = self.command(self.owner, 'invite', tree_id=self.tree.pk, anchor_id=(anchor or self.person).pk, mode=mode, **extra)
        self.assertEqual(response.status_code, 201, response.data)
        return response.data

    def approve(self, invitation):
        response = self.command(self.user, 'redeem', code=invitation['code'])
        self.assertEqual(response.status_code, 201, response.data)
        reviewed = self.command(self.owner, 'review', tree_id=self.tree.pk, request_id=response.data['id'], decision='APPROVED')
        self.assertEqual(reviewed.status_code, 200, reviewed.data)
        return reviewed.data

    def test_existing_profile_is_reused_and_viewer_cannot_write(self):
        invite = self.invite()
        self.assertNotEqual(FamilyInvitation.objects.get(pk=invite['id']).secret_digest, invite['code'])
        request = self.command(self.user, 'redeem', code=invite['code'])
        self.client.force_authenticate(self.user)
        self.assertEqual(self.client.get(f'/api/people/{self.person.pk}/').status_code, 404)
        result = self.command(self.owner, 'review', tree_id=self.tree.pk, request_id=request.data['id'], decision='APPROVED')
        self.assertEqual(result.status_code, 200, result.data)
        self.assertEqual(result.data['person_id'], self.person.pk)
        self.assertEqual(Person.objects.count(), 3)
        self.person.refresh_from_db()
        self.assertEqual(self.person.biography, 'Keep me')
        self.client.force_authenticate(self.user)
        self.assertEqual(self.client.get(f'/api/people/{self.person.pk}/').status_code, 200)
        self.assertEqual(self.client.patch(f'/api/people/{self.person.pk}/', {'biography': 'Forbidden'}, format='json').status_code, 403)
        self.assertEqual(self.client.delete(f'/api/relationships/{self.child_link.pk}/').status_code, 403)
        self.assertEqual(self.client.post('/api/people/', {'family_tree': self.tree.pk, 'first_name': 'Forbidden', 'last_name': 'Write', 'gender': 'O'}, format='json').status_code, 403)
        trees = self.client.get('/api/trees/').data['results']
        self.assertFalse(trees[0]['can_edit'])
        self.assertFalse(trees[0]['can_manage'])

    def test_replay_expiry_revocation_and_claim_competition(self):
        invite = self.invite()
        first = self.command(self.user, 'redeem', code=invite['code'])
        again = self.command(self.user, 'redeem', code=invite['code'])
        self.assertEqual(again.data['id'], first.data['id'])
        self.assertEqual(self.command(self.other, 'redeem', code=invite['code']).status_code, 400)
        second = self.invite()
        competitor = self.command(self.other, 'redeem', code=second['code'])
        self.assertEqual(competitor.status_code, 201, competitor.data)
        self.assertEqual(self.command(self.owner, 'review', tree_id=self.tree.pk, request_id=first.data['id'], decision='APPROVED').status_code, 200)
        self.assertEqual(self.command(self.owner, 'review', tree_id=self.tree.pk, request_id=competitor.data['id'], decision='APPROVED').status_code, 400)
        self.assertEqual(TreeMembership.objects.filter(person=self.person).count(), 1)
        expired = self.invite('CHILD', self.parent)
        FamilyInvitation.objects.filter(pk=expired['id']).update(expires_at=timezone.now()-timedelta(seconds=1))
        self.assertEqual(self.command(self.other, 'redeem', code=expired['code']).status_code, 400)
        revoked = self.invite('CHILD', self.parent)
        pending = self.command(self.other, 'redeem', code=revoked['code'])
        self.command(self.owner, 'revoke', tree_id=self.tree.pk, invitation_id=revoked['id'])
        self.assertEqual(self.command(self.owner, 'review', tree_id=self.tree.pk, request_id=pending.data['id'], decision='APPROVED').status_code, 400)

    def test_grandchild_connects_through_actual_parent_and_rolls_back_invalid_dates(self):
        invite = self.invite('GRANDCHILD', self.gp, through_parent_id=self.parent.pk)
        pending = self.command(self.user, 'redeem', code=invite['code'], person={'first_name': 'New', 'last_name': 'Child'})
        self.assertEqual(self.command(self.owner, 'review', tree_id=self.tree.pk, request_id=pending.data['id'], decision='APPROVED').status_code, 200)
        person = Person.objects.get(first_name='New')
        self.assertTrue(Relationship.objects.filter(person1=self.parent, person2=person).exists())
        self.assertFalse(Relationship.objects.filter(person1=self.gp, person2=person).exists())
        self.assertEqual(self.command(self.owner, 'invite', tree_id=self.tree.pk, anchor_id=self.gp.pk, mode='GRANDCHILD', through_parent_id=self.person.pk).status_code, 400)
        invite = self.invite('CHILD', self.parent)
        pending = self.command(self.other, 'redeem', code=invite['code'], person={'first_name': 'Bad', 'last_name': 'Dates', 'date_of_birth': '1900-01-01'})
        self.parent.date_of_birth = '1980-01-01'; self.parent.save()
        before = Person.objects.count()
        self.assertEqual(self.command(self.owner, 'review', tree_id=self.tree.pk, request_id=pending.data['id'], decision='APPROVED').status_code, 400)
        self.assertEqual(Person.objects.count(), before)
        self.assertFalse(self.tree.members.filter(pk=self.other.pk).exists())

    def test_roles_removal_and_owner_transfer(self):
        self.approve(self.invite())
        self.assertEqual(self.command(self.user, 'role', tree_id=self.tree.pk, user_id=self.user.pk, role='EDITOR').status_code, 403)
        self.assertEqual(self.command(self.owner, 'role', tree_id=self.tree.pk, user_id=self.user.pk, role='EDITOR').status_code, 200)
        self.client.force_authenticate(self.user)
        self.assertEqual(self.client.patch(f'/api/people/{self.person.pk}/', {'biography': 'Allowed'}, format='json').status_code, 200)
        self.assertEqual(self.client.patch(f'/api/trees/{self.tree.pk}/', {'name': 'Forbidden'}, format='json').status_code, 403)
        self.assertEqual(self.command(self.owner, 'transfer', tree_id=self.tree.pk, user_id=self.user.pk).status_code, 200)
        self.tree.refresh_from_db(); self.assertEqual(self.tree.owner_id, self.user.pk)
        self.assertEqual(self.command(self.owner, 'discovery', tree_id=self.tree.pk, enabled=True).status_code, 403)
        self.assertEqual(self.command(self.user, 'remove', tree_id=self.tree.pk, user_id=self.owner.pk).status_code, 200)
        self.client.force_authenticate(self.owner)
        self.assertEqual(self.client.get(f'/api/people/{self.person.pk}/').status_code, 404)

    def test_matching_requires_consent_connected_path_and_never_exposes_profiles(self):
        facts = {'parent_name': '  paul family ', 'grandparent_name': 'MARIAM FAMILY'}
        self.assertEqual(self.command(self.user, 'matches', **facts).data['matches'], [])
        self.command(self.owner, 'discovery', tree_id=self.tree.pk, enabled=True)
        result = self.command(self.user, 'matches', **facts)
        self.assertEqual(len(result.data['matches']), 1)
        match = result.data['matches'][0]
        self.assertEqual(set(match), {'candidate', 'family_name', 'reason', 'relationship_type'})
        self.assertFalse(self.tree.members.filter(pk=self.user.pk).exists())
        self.assertEqual(self.command(self.other, 'request_match', candidate=match['candidate'], person={'first_name':'Other', 'last_name':'One'}).status_code, 403)
        pending = self.command(self.user, 'request_match', candidate=match['candidate'])
        self.assertEqual(pending.status_code, 201, pending.data)
        self.assertEqual(JoinRequest.objects.get(pk=pending.data['id']).anchor_id, self.person.pk)
        approved = self.command(self.owner, 'review', tree_id=self.tree.pk, request_id=pending.data['id'], decision='APPROVED')
        self.assertEqual(approved.status_code, 200, approved.data)
        self.assertEqual(Person.objects.count(), 3)
        self.gp_link.delete()
        self.assertEqual(self.command(self.other, 'matches', **facts).data['matches'], [])

    def test_matching_rejects_conflicting_facts_and_invalid_tokens(self):
        self.command(self.owner, 'discovery', tree_id=self.tree.pk, enabled=True)
        self.parent.date_of_birth = '1980-01-01'; self.parent.save()
        facts = {'parent_name': 'Paul Family', 'grandparent_name': 'Mariam Family'}
        self.assertEqual(self.command(self.user, 'matches', **facts, parent_birth_date='1990-01-01').data['matches'], [])
        self.assertEqual(self.command(self.user, 'matches', parent_name='Family').status_code, 400)
        self.assertEqual(self.command(self.user, 'request_match', candidate='invented').status_code, 400)
        match = self.command(self.user, 'matches', **facts).data['matches'][0]
        self.command(self.owner, 'discovery', tree_id=self.tree.pk, enabled=False)
        self.assertEqual(self.command(self.user, 'request_match', candidate=match['candidate']).status_code, 400)

    def test_rejected_cancelled_requests_grant_nothing(self):
        invite = self.invite()
        pending = self.command(self.user, 'redeem', code=invite['code'])
        self.assertEqual(self.command(self.other, 'cancel', request_id=pending.data['id']).status_code, 404)
        self.command(self.user, 'cancel', request_id=pending.data['id'])
        result = self.command(self.owner, 'review', tree_id=self.tree.pk, request_id=pending.data['id'], decision='APPROVED')
        self.assertEqual(result.data['status'], 'CANCELLED')
        self.assertFalse(self.tree.members.filter(pk=self.user.pk).exists())
        pending = self.command(self.user, 'redeem', code=self.invite()['code'])
        self.command(self.owner, 'review', tree_id=self.tree.pk, request_id=pending.data['id'], decision='REJECTED')
        self.assertFalse(self.tree.members.filter(pk=self.user.pk).exists())

    def test_revision_conflict_and_namesakes_are_safe(self):
        self.client.force_authenticate(self.owner)
        url = f'/api/people/{self.person.pk}/'
        self.assertEqual(self.client.patch(url, {'revision': 1, 'biography': 'First'}, format='json').status_code, 200)
        self.assertEqual(self.client.patch(url, {'revision': 1, 'biography': 'Stale'}, format='json').status_code, 409)
        self.person.refresh_from_db(); self.assertEqual(self.person.biography, 'First')
        self.assertEqual(RecordChange.objects.filter(kind='PERSON_EDIT').count(), 1)
        for _ in range(2):
            response = self.client.post('/api/people/', {'family_tree': self.tree.pk, 'first_name':'Namesake', 'last_name':'Family', 'date_of_birth':'2000-01-01'}, format='json')
            self.assertEqual(response.status_code, 201, response.data)

    def test_owner_deletion_is_protected_and_detached_profile_survives(self):
        with self.assertRaises(ProtectedError): self.owner.delete()
        self.person.user = self.other; self.person.save()
        self.other.delete()
        self.person.refresh_from_db(); self.assertIsNone(self.person.user_id)

    def test_import_replay_is_one_operation_and_unknown_gender_is_neutral(self):
        data = {'people': [{'pk': 1, 'fields': {'first_name':'Imported', 'last_name':'Family'}}], 'relationships': []}
        self.client.force_authenticate(self.owner)
        def send(payload=data):
            return self.client.post('/api/data/import/', {'tree_id': self.tree.pk, 'file': SimpleUploadedFile('tree.json', json.dumps(payload).encode())}, HTTP_IDEMPOTENCY_KEY='same-import')
        first = send(); second = send()
        self.assertEqual(first.status_code, 201, first.data)
        self.assertEqual(first.data, second.data)
        self.assertEqual(Person.objects.filter(first_name='Imported').count(), 1)
        self.assertEqual(Person.objects.get(first_name='Imported').gender, 'O')
        self.assertEqual(send({'people': [], 'relationships': []}).status_code, 409)

    def test_invalid_identifiers_and_owner_data_remain_private(self):
        self.assertEqual(self.command(self.owner, 'invite', tree_id='bad', anchor_id=self.person.pk, mode='EXISTING').status_code, 400)
        self.client.force_authenticate(self.other)
        self.assertEqual(self.client.get(f'/api/family-access/?tree_id={self.tree.pk}').status_code, 403)
        self.assertEqual(self.client.get('/api/family-access/?tree_id=bad').status_code, 400)

    def test_match_rechecks_path_and_facts_before_owner_approval(self):
        self.tree.discovery_enabled = True
        self.tree.save()
        self.parent.date_of_birth = '1980-01-01'
        self.parent.save()
        candidate = self.command(self.user, 'matches', parent_name='Paul Family',
            grandparent_name='Mariam Family', parent_birth_date='1980-01-01').data['matches'][0]['candidate']
        pending = self.command(self.user, 'request_match', candidate=candidate)
        self.assertEqual(pending.status_code, 201, pending.data)
        self.parent.date_of_birth = '1981-01-01'
        self.parent.save()
        self.assertEqual(self.command(self.owner, 'review', tree_id=self.tree.pk,
            request_id=pending.data['id'], decision='APPROVED').status_code, 400)
        self.assertEqual(self.command(self.other, 'request_match', candidate=candidate).status_code, 403)
        self.parent.date_of_birth = '1980-01-01'
        self.parent.save()
        self.gp_link.delete()
        self.assertEqual(self.command(self.owner, 'review', tree_id=self.tree.pk,
            request_id=pending.data['id'], decision='APPROVED').status_code, 400)
        self.assertFalse(self.tree.members.filter(pk=self.user.pk).exists())

    def test_adopted_profile_reused_and_stale_person_name_rejected(self):
        self.child_link.relationship_type = 'ADOPTED'
        self.child_link.save()
        self.tree.discovery_enabled = True
        self.tree.save()
        candidate = self.command(self.user, 'matches', parent_name='Paul Family',
            grandparent_name='Mariam Family').data['matches'][0]['candidate']
        pending = self.command(self.user, 'request_match', candidate=candidate)
        self.assertEqual(pending.data['mode'], 'EXISTING')
        self.person.first_name = 'Different'
        self.person.save()
        self.assertEqual(self.command(self.owner, 'review', tree_id=self.tree.pk,
            request_id=pending.data['id'], decision='APPROVED').status_code, 400)
        self.person.first_name = 'Anna'
        self.person.save()
        self.assertEqual(self.command(self.owner, 'review', tree_id=self.tree.pk,
            request_id=pending.data['id'], decision='APPROVED').data['person_id'], self.person.pk)
        self.assertEqual(Person.objects.count(), 3)

    def test_default_import_retry_reuses_receipt_after_tree_creation(self):
        self.client.force_authenticate(self.other)
        document = json.dumps({'people': [{'pk': 1, 'fields': {'first_name': 'Retry', 'last_name': 'Import'}}], 'relationships': []}).encode()
        def upload():
            return self.client.post('/api/data/import/', {'file': SimpleUploadedFile('tree.json', document)}, HTTP_IDEMPOTENCY_KEY='default-import-retry')
        first = upload()
        second = upload()
        self.assertEqual(first.status_code, 201, first.data)
        self.assertEqual(second.status_code, 201, second.data)
        self.assertEqual(first.data, second.data)
        self.assertEqual(Person.objects.filter(first_name='Retry').count(), 1)

    def test_transfer_upgrades_previous_owner_and_invalid_payload_is_400(self):
        self.approve(self.invite())
        TreeMembership.objects.create(tree=self.tree, user=self.owner, role='VIEWER')
        response = self.command(self.owner, 'transfer', tree_id=self.tree.pk, user_id=self.user.pk)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(TreeMembership.objects.get(tree=self.tree, user=self.owner).role, 'EDITOR')
        self.client.force_authenticate(self.user)
        self.assertEqual(self.client.post('/api/family-access/', ['invalid'], format='json').status_code, 400)


@skipUnless(connection.vendor == 'postgresql', 'Row locking requires PostgreSQL')
class ConcurrentFamilyClaimTests(TransactionTestCase):
    def test_competing_approvals_confirm_only_one_account(self):
        from . import joining
        User = get_user_model()
        owner = User.objects.create_user(username='concurrent-owner', email='owner@concurrent.test')
        tree = FamilyTree.objects.create(name='Concurrent family', owner=owner)
        person = Person.objects.create(family_tree=tree, first_name='Recorded', last_name='Person', gender='O')
        requests = []
        for index in range(2):
            applicant = User.objects.create_user(username=f'concurrent-{index}', email=f'{index}@concurrent.test', first_name='Recorded', last_name='Person')
            invitation = joining.invite(owner, {'tree_id': tree.pk, 'anchor_id': person.pk, 'mode': 'EXISTING'})
            requests.append(joining.redeem(applicant, {'code': invitation['code']}).pk)
        barrier = Barrier(2)
        def approve(request_id):
            close_old_connections()
            try:
                barrier.wait(timeout=10)
                try:
                    joining.review(owner, {'tree_id': tree.pk, 'request_id': request_id, 'decision': 'APPROVED'})
                    return 'APPROVED'
                except ValidationError:
                    return 'CONFLICT'
            finally:
                connections.close_all()
        with ThreadPoolExecutor(max_workers=2) as pool:
            outcomes = list(pool.map(approve, requests))
        self.assertCountEqual(outcomes, ['APPROVED', 'CONFLICT'])
        self.assertEqual(TreeMembership.objects.filter(person=person).count(), 1)
        self.assertEqual(tree.members.count(), 1)
        self.assertEqual(JoinRequest.objects.filter(tree=tree, status='APPROVED').count(), 1)
