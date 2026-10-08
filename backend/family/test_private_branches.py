from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.test import TestCase
from rest_framework.test import APIClient
from .models import FamilyTree, Person, Relationship, TreeMembership, FamilyBranchLink


class PrivateBranchTests(TestCase):
    def setUp(self):
        cache.clear()
        User = get_user_model()
        self.owner = User.objects.create_user(username='extended-owner', email='extended@branch.test')
        self.branch_owner = User.objects.create_user(username='private-owner', email='private@branch.test')
        self.member = User.objects.create_user(username='reader', email='reader@branch.test')
        self.stranger = User.objects.create_user(username='outsider', email='outsider@branch.test')
        self.extended = FamilyTree.objects.create(name='Extended', owner=self.owner)
        self.private = FamilyTree.objects.create(name='Private household', owner=self.branch_owner)
        self.extended.members.add(self.branch_owner, self.member)
        self.anchor = Person.objects.create(family_tree=self.extended, first_name='Anna', last_name='Family')
        self.root = Person.objects.create(family_tree=self.private, first_name='Anna', last_name='Family', biography='Never share this story')
        self.child = Person.objects.create(family_tree=self.private, first_name='Shared', last_name='Child')
        self.hidden = Person.objects.create(family_tree=self.private, first_name='Secret', last_name='Relative', birth_place='Secret place')
        for child in (self.child, self.hidden):
            Relationship.objects.create(person1=self.root, person2=child, relationship_type='PARENT')
        self.client = APIClient()
        self.payload = {'source_tree_id': self.private.pk, 'target_tree_id': self.extended.pk,
            'root_id': self.root.pk, 'attachment_id': self.anchor.pk, 'label': 'Anna’s household',
            'connection': 'EXISTING', 'shared_ids': [self.root.pk, self.child.pk]}

    def post(self, user, action, **data):
        self.client.force_authenticate(user)
        return self.client.post('/api/family-branches/', {'action': action, **data}, format='json')

    def get(self, user, tree):
        self.client.force_authenticate(user)
        return self.client.get(f'/api/family-branches/?tree_id={tree.pk}')

    def publish(self, **extra):
        response = self.post(self.branch_owner, 'publish', **{**self.payload, **extra})
        self.assertEqual(response.status_code, 201, response.data)
        return response.data

    def approve(self, link):
        response = self.post(self.owner, 'review', link_id=link['id'], revision=link['revision'], decision='APPROVED')
        self.assertEqual(response.status_code, 200, response.data)
        return response.data

    def test_only_selected_projection_is_visible_after_approval(self):
        link = self.publish()
        self.assertEqual(self.get(self.member, self.extended).data['visible'], [])
        self.assertEqual(len(self.get(self.owner, self.extended).data['incoming']), 1)
        self.client.force_authenticate(self.owner)
        self.assertEqual(self.client.get('/api/family-access/').data['pending_reviews'], 1)
        self.approve(link)
        result = self.get(self.member, self.extended).data['visible'][0]
        self.assertEqual({p['id'] for p in result['people']}, {self.root.pk, self.child.pk})
        self.assertEqual(len(result['relationships']), 1)
        self.assertNotIn('biography', result['people'][0])
        self.assertNotIn('profile_picture', result['people'][0])
        self.assertNotIn('parents', result['people'][0])
        self.assertNotIn('source_tree_id', result)
        self.assertNotIn('Secret', str(result))
        self.assertEqual(self.get(self.member, self.private).status_code, 404)
        self.client.force_authenticate(self.member)
        self.assertEqual(self.client.get(f'/api/people/{self.root.pk}/').status_code, 404)
        self.assertFalse(self.private.members.filter(pk=self.member.pk).exists())
        self.assertFalse(TreeMembership.objects.filter(tree=self.private).exists())

    def test_withdrawing_removes_projection_even_for_target_owner(self):
        link = self.approve(self.publish())
        result = self.post(self.branch_owner, 'withdraw', link_id=link['id'], revision=link['revision'])
        self.assertEqual(result.status_code, 200)
        for user in (self.owner, self.member):
            response = self.get(user, self.extended).data
            self.assertEqual(response['visible'], [])
            self.assertEqual(response['incoming'], [])
        self.assertEqual(self.post(self.owner, 'review', link_id=link['id'], revision=result.data['revision'], decision='APPROVED').status_code, 400)

    def test_editing_shared_selection_requires_a_new_review(self):
        link = self.approve(self.publish())
        updated = self.publish(link_id=link['id'], revision=link['revision'], shared_ids=[self.root.pk])
        self.assertEqual(updated['status'], 'PENDING')
        self.assertEqual(self.get(self.member, self.extended).data['visible'], [])
        self.approve(updated)
        self.assertEqual(len(self.get(self.member, self.extended).data['visible'][0]['people']), 1)
        self.assertEqual(self.post(self.branch_owner, 'withdraw', link_id=link['id'], revision=link['revision']).status_code, 409)

    def test_only_source_owner_can_publish_and_only_target_owner_can_review(self):
        self.private.members.add(self.member)
        self.assertEqual(self.post(self.member, 'publish', **self.payload).status_code, 403)
        self.assertEqual(self.post(self.stranger, 'publish', **self.payload).status_code, 403)
        link = self.publish()
        self.assertEqual(self.post(self.branch_owner, 'review', link_id=link['id'], revision=link['revision'], decision='APPROVED').status_code, 403)
        self.assertEqual(self.post(self.owner, 'withdraw', link_id=link['id'], revision=link['revision']).status_code, 403)
        self.assertEqual(self.get(self.stranger, self.extended).status_code, 404)

    def test_foreign_profiles_invalid_identity_and_unshared_root_are_rejected(self):
        for extra in ({'shared_ids': [self.child.pk]}, {'shared_ids': [self.root.pk, self.anchor.pk]},
                {'root_id': self.anchor.pk}, {'attachment_id': self.hidden.pk}, {'source_tree_id': self.extended.pk}):
            response = self.post(self.branch_owner, 'publish', **{**self.payload, **extra})
            self.assertIn(response.status_code, (400, 403))
        self.root.first_name = 'Another'; self.root.save()
        self.assertEqual(self.post(self.branch_owner, 'publish', **self.payload).status_code, 400)
        self.assertFalse(FamilyBranchLink.objects.exists())

    def test_membership_and_ownership_changes_stop_sharing(self):
        self.approve(self.publish())
        self.extended.members.remove(self.branch_owner)
        self.assertEqual(self.get(self.member, self.extended).data['visible'], [])
        self.extended.members.add(self.branch_owner)
        self.private.owner = self.stranger; self.private.save()
        self.assertEqual(self.get(self.member, self.extended).data['visible'], [])

    def test_invalid_pending_consent_does_not_leave_unresolvable_review_badges(self):
        self.publish()
        self.client.force_authenticate(self.owner)
        self.assertEqual(self.client.get('/api/family-access/').data['pending_reviews'], 1)
        self.extended.members.remove(self.branch_owner)
        self.assertEqual(self.client.get('/api/family-access/').data['pending_reviews'], 0)
        self.assertEqual(self.client.get(f'/api/family-access/?tree_id={self.extended.pk}').data['pending_branches'], 0)
        self.client.force_authenticate(self.branch_owner)
        self.assertEqual(self.client.get('/api/family-access/').data['pending_requests'], 0)
        self.extended.members.add(self.branch_owner)
        self.private.owner = self.stranger; self.private.save()
        self.assertEqual(self.client.get('/api/family-access/').data['pending_requests'], 0)

    def test_same_person_changes_and_moved_profiles_stop_sharing(self):
        self.approve(self.publish())
        self.anchor.first_name = 'Corrected'; self.anchor.save()
        self.assertEqual(self.get(self.member, self.extended).data['visible'], [])

    def test_plural_partners_and_union_specific_parentage_are_supported(self):
        wife1 = Person.objects.create(family_tree=self.private, first_name='First', last_name='Partner')
        wife2 = Person.objects.create(family_tree=self.private, first_name='Second', last_name='Partner')
        self.client.force_authenticate(self.branch_owner)
        for partner in (wife1, wife2):
            response = self.client.post('/api/relationships/', {'person1': self.root.pk, 'person2': partner.pk, 'relationship_type': 'SPOUSE'}, format='json')
            self.assertEqual(response.status_code, 201, response.data)
        self.assertEqual(self.root.get_spouses().count(), 2)
        response = self.client.post(f'/api/people/{self.root.pk}/create_relative/', {'role': 'child', 'person': {'first_name': 'Union', 'last_name': 'Child'}, 'co_parent_id': wife2.pk}, format='json')
        self.assertEqual(response.status_code, 201, response.data)
        child = Person.objects.get(pk=response.data['person']['id'])
        self.assertEqual(set(child.get_parents().values_list('pk', flat=True)), {self.root.pk, wife2.pk})
