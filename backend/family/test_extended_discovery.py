from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.test import TestCase
from rest_framework.test import APIClient

from .models import FamilyTree, JoinRequest, Person, Relationship, TreeMembership


class ExtendedDiscoveryTests(TestCase):
    def setUp(self):
        cache.clear()
        User = get_user_model()
        self.owner = User.objects.create_user(username='roots-owner', email='owner@roots.test')
        self.user = User.objects.create_user(username='roots-applicant', email='applicant@roots.test', first_name='Anna', last_name='Family')
        self.other = User.objects.create_user(username='roots-other', email='other@roots.test')
        self.tree = FamilyTree.objects.create(name='Extended family', owner=self.owner, discovery_enabled=True)
        self.great = Person.objects.create(family_tree=self.tree, first_name='Samuel', last_name='Family', birth_place='Bafoussam', date_of_birth='1900-01-01')
        self.gp = Person.objects.create(family_tree=self.tree, first_name='Mariam', last_name='Family', birth_place='Yaoundé', date_of_birth='1930-01-01')
        self.parent = Person.objects.create(family_tree=self.tree, first_name='Paul', last_name='Family')
        self.person = Person.objects.create(family_tree=self.tree, first_name='Anna', last_name='Family')
        for ancestor, child in [(self.great, self.gp), (self.gp, self.parent), (self.parent, self.person)]:
            Relationship.objects.create(person1=ancestor, person2=child, relationship_type='PARENT')
        self.facts = {'parent_name': 'Mariam Family', 'grandparent_name': 'Samuel Family', 'ancestor_level': 2,
            'parent_birth_place': ' yaounde ', 'parent_birth_date': '1930-01-01',
            'grandparent_birth_place': 'Bafoussam', 'grandparent_birth_date': '1900-01-01'}
        self.client = APIClient()

    def command(self, user, action, **payload):
        self.client.force_authenticate(user)
        return self.client.post('/api/family-access/', {'action': action, **payload}, format='json')

    def candidate(self, **facts):
        result = self.command(self.user, 'matches', **{**self.facts, **facts})
        self.assertEqual(result.status_code, 200, result.data)
        return result.data['matches'][0]['candidate']

    def pending(self, **extra):
        response = self.command(self.user, 'request_match', candidate=self.candidate(), **extra)
        self.assertEqual(response.status_code, 201, response.data)
        return response.data

    def review(self, request, **extra):
        return self.command(self.owner, 'review', tree_id=self.tree.pk, request_id=request['id'], decision='APPROVED', **extra)

    def test_grandparent_match_reports_only_corroborated_fields(self):
        response = self.command(self.user, 'matches', **self.facts)
        match = response.data['matches'][0]
        self.assertEqual(match['evidence_level'], 'CORROBORATED')
        self.assertEqual(len(match['matched_facts']), 4)
        self.assertNotIn('parent', match)
        self.assertNotIn('tree_id', match)
        self.assertNotIn('birth_place', match)
        self.gp.birth_place = ''; self.gp.date_of_birth = None; self.gp.save()
        self.great.birth_place = ''; self.great.date_of_birth = None; self.great.save()
        match = self.command(self.user, 'matches', **self.facts).data['matches'][0]
        self.assertEqual(match['matched_facts'], [])
        self.assertEqual(match['evidence_level'], 'NAMES_ONLY')

    def test_conflicting_birth_details_on_either_ancestor_exclude_candidate(self):
        for field, wrong in [('parent_birth_place', 'Douala'), ('grandparent_birth_place', 'Douala'),
                ('parent_birth_date', '1931-01-01'), ('grandparent_birth_date', '1901-01-01')]:
            with self.subTest(field=field):
                response = self.command(self.user, 'matches', **{**self.facts, field: wrong})
                self.assertEqual(response.data['matches'], [])
        self.assertEqual(self.command(self.user, 'matches', **{**self.facts, 'ancestor_level': 4}).status_code, 400)

    def test_inquiry_notifies_owner_and_reply_grants_no_access(self):
        pending = self.pending(purpose='INQUIRE', message='My grandmother may belong to this branch.')
        self.assertEqual(pending['mode'], 'INQUIRY')
        self.client.force_authenticate(self.owner)
        self.assertEqual(self.client.get('/api/family-access/').data['pending_reviews'], 1)
        result = self.command(self.owner, 'reply', tree_id=self.tree.pk, request_id=pending['id'], message='Please confirm your parent’s name.')
        self.assertEqual(result.status_code, 200)
        self.client.force_authenticate(self.user)
        own = self.client.get('/api/family-access/').data['requests'][0]
        self.assertEqual(own['owner_response'], 'Please confirm your parent’s name.')
        self.assertNotIn('evidence', own)
        self.assertNotIn('tree_id', own)
        self.assertEqual(self.client.get(f'/api/people/{self.gp.pk}/').status_code, 404)
        self.assertEqual(self.command(self.other, 'reply', tree_id=self.tree.pk, request_id=pending['id'], message='Other').status_code, 403)
        self.assertEqual(self.command(self.owner, 'reply', tree_id=self.tree.pk, request_id=pending['id'], message='x' * 1001).status_code, 400)

    def test_owner_must_confirm_real_generation_before_membership(self):
        pending = self.pending()
        self.assertEqual(self.review(pending).status_code, 400)
        self.assertEqual(self.review(pending, connection_mode='CHILD', anchor_id=self.gp.pk).status_code, 400)
        self.assertEqual(self.review(pending, connection_mode='EXISTING', anchor_id=self.parent.pk).status_code, 400)
        self.assertFalse(self.tree.members.filter(pk=self.user.pk).exists())
        result = self.review(pending, connection_mode='EXISTING', anchor_id=self.person.pk)
        self.assertEqual(result.status_code, 200, result.data)
        self.assertEqual(result.data['person_id'], self.person.pk)
        self.assertEqual(Person.objects.filter(family_tree=self.tree).count(), 4)
        self.assertEqual(TreeMembership.objects.get(user=self.user).role, 'VIEWER')

    def test_missing_child_is_added_under_actual_parent_not_grandparent(self):
        self.person.delete()
        pending = self.pending(purpose='JOIN')
        result = self.review(pending, connection_mode='CHILD', anchor_id=self.parent.pk, relationship_type='ADOPTED')
        self.assertEqual(result.status_code, 200, result.data)
        person = TreeMembership.objects.get(user=self.user).person
        self.assertTrue(Relationship.objects.filter(person1=self.parent, person2=person, relationship_type='ADOPTED').exists())
        self.assertFalse(Relationship.objects.filter(person1=self.gp, person2=person).exists())

    def test_great_grandparent_match_requires_three_recorded_generations(self):
        older = Person.objects.create(family_tree=self.tree, first_name='Older', last_name='Family')
        Relationship.objects.create(person1=older, person2=self.great, relationship_type='PARENT')
        token = self.candidate(parent_name='Samuel Family', grandparent_name='Older Family', ancestor_level=3,
            parent_birth_place='', grandparent_birth_place='', parent_birth_date=None, grandparent_birth_date=None)
        pending = self.command(self.user, 'request_match', candidate=token).data
        result = self.review(pending, connection_mode='EXISTING', anchor_id=self.person.pk)
        self.assertEqual(result.status_code, 200, result.data)

    def test_deleted_path_changed_facts_and_wrong_identity_prevent_approval(self):
        pending = self.pending()
        self.great.birth_place = 'Douala'; self.great.save()
        self.assertEqual(self.review(pending, connection_mode='EXISTING', anchor_id=self.person.pk).status_code, 400)
        self.great.birth_place = 'Bafoussam'; self.great.save()
        self.person.first_name = 'Someone'; self.person.save()
        self.assertEqual(self.review(pending, connection_mode='EXISTING', anchor_id=self.person.pk).status_code, 400)
        Relationship.objects.filter(person1=self.gp, person2=self.parent).delete()
        self.assertEqual(self.review(pending, connection_mode='CHILD', anchor_id=self.parent.pk).status_code, 400)
        self.assertEqual(JoinRequest.objects.get(pk=pending['id']).status, 'PENDING')

    def test_stronger_supported_match_is_not_hidden_behind_ten_namesakes(self):
        for index in range(11):
            tree = FamilyTree.objects.create(name=f'Namesake {index}', owner=self.other, discovery_enabled=True)
            gp = Person.objects.create(family_tree=tree, first_name='Samuel', last_name='Family')
            parent = Person.objects.create(family_tree=tree, first_name='Mariam', last_name='Family')
            Relationship.objects.create(person1=gp, person2=parent, relationship_type='PARENT')
        Relationship.objects.filter(person1=self.great, person2=self.gp).delete()
        Relationship.objects.create(person1=self.great, person2=self.gp, relationship_type='PARENT')
        response = self.command(self.user, 'matches', **self.facts)
        self.assertEqual(len(response.data['matches']), 10)
        self.assertEqual(response.data['matches'][0]['family_name'], self.tree.name)

    def test_inquiring_about_parent_pair_also_requires_owner_placement(self):
        token = self.candidate(parent_name='Paul Family', grandparent_name='Mariam Family', ancestor_level=1,
            parent_birth_place='', parent_birth_date=None, grandparent_birth_place='', grandparent_birth_date=None)
        pending = self.command(self.user, 'request_match', candidate=token, purpose='INQUIRE').data
        self.assertEqual(pending['mode'], 'INQUIRY')
        self.assertEqual(self.review(pending, connection_mode='EXISTING', anchor_id=self.person.pk).status_code, 200)
