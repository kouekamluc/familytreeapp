from datetime import date
from django.contrib.auth import get_user_model
from django.db import connection
from django.test import TestCase, override_settings
from django.test.utils import CaptureQueriesContext
from rest_framework.test import APIClient
from family.models import FamilyTree, Person, Relationship


class WorkflowCompletionTests(TestCase):
    def setUp(self):
        self.owner = get_user_model().objects.create_user(username='workflow-owner')
        self.member = get_user_model().objects.create_user(username='workflow-member', email='member@example.test')
        self.visitor = get_user_model().objects.create_user(username='workflow-visitor', email='visitor@example.test')
        self.tree = FamilyTree.objects.create(name='Family', owner=self.owner, is_public=True)
        self.tree.members.add(self.member)
        self.source = Person.objects.create(family_tree=self.tree, first_name='Parent', last_name='One', gender='O', date_of_birth=date(1980, 1, 1))
        self.client = APIClient()
        self.client.force_authenticate(self.owner)

    @override_settings(ALLOW_PUBLIC_FAMILY_READS=True)
    def test_chooser_permissions_are_real_and_records_are_not_nested(self):
        for user, edit, manage in [(self.owner, True, True), (self.member, True, False), (self.visitor, False, False)]:
            self.client.force_authenticate(user)
            response = self.client.get('/api/trees/')
            self.assertEqual(response.status_code, 200, response.data)
            record = response.data['results'][0]
            self.assertEqual((record['can_edit'], record['can_manage']), (edit, manage))
            self.assertEqual(record['people_count'], 1)
            self.assertNotIn('people', record)

    def test_tree_rename_and_delete_enforce_owner_and_preserve_other_trees(self):
        other = FamilyTree.objects.create(name='Keep', owner=self.owner)
        self.client.force_authenticate(self.member)
        self.assertEqual(self.client.patch(f'/api/trees/{self.tree.pk}/', {'name':'Forbidden'}, format='json').status_code, 403)
        self.assertEqual(self.client.delete(f'/api/trees/{self.tree.pk}/').status_code, 403)
        self.client.force_authenticate(self.owner)
        self.assertEqual(self.client.patch(f'/api/trees/{self.tree.pk}/', {'name':'Renamed', 'description':'Recorded'}, format='json').status_code, 200)
        self.assertEqual(self.client.delete(f'/api/trees/{self.tree.pk}/').status_code, 204)
        self.assertFalse(Person.objects.filter(pk=self.source.pk).exists())
        self.assertTrue(FamilyTree.objects.filter(pk=other.pk).exists())
        self.assertTrue(get_user_model().objects.filter(pk=self.owner.pk).exists())

    def test_invalid_starting_person_rolls_back_tree(self):
        response = self.client.post('/api/trees/', {'name':'Invalid', 'starting_person':{'first_name':'New', 'last_name':'Person', 'date_of_birth':'2000-01-01', 'date_of_death':'1990-01-01', 'is_living':False}}, format='json')
        self.assertEqual(response.status_code, 400, response.data)
        self.assertEqual(FamilyTree.objects.count(), 1)
        self.assertEqual(Person.objects.count(), 1)

    def test_invalid_co_parent_rolls_back_both_child_and_first_link(self):
        young = Person.objects.create(family_tree=self.tree, first_name='Young', last_name='Parent', gender='O', date_of_birth=date(2025, 1, 1))
        response = self.client.post(f'/api/people/{self.source.pk}/create_relative/', {'role':'child', 'person':{'first_name':'Child', 'last_name':'One', 'date_of_birth':'2020-01-01'}, 'co_parent_id':young.pk}, format='json')
        self.assertEqual(response.status_code, 400, response.data)
        self.assertEqual(Person.objects.count(), 2)
        self.assertEqual(Relationship.objects.count(), 0)

    def test_existing_child_co_parent_and_notes_are_atomic_and_retry_safe(self):
        co_parent = Person.objects.create(family_tree=self.tree, first_name='Other', last_name='Parent', gender='O')
        child = Person.objects.create(family_tree=self.tree, first_name='Child', last_name='One', gender='O')
        data = {'role':'child', 'person':{}, 'existing_person_id':child.pk, 'co_parent_id':co_parent.pk, 'relationship_notes':'Recorded parentage'}
        url = f'/api/people/{self.source.pk}/create_relative/'
        first = self.client.post(url, data, format='json', HTTP_IDEMPOTENCY_KEY='compound-link')
        second = self.client.post(url, data, format='json', HTTP_IDEMPOTENCY_KEY='compound-link')
        self.assertEqual(first.status_code, 201, first.data)
        self.assertEqual(second.data, first.data)
        self.assertEqual(Relationship.objects.count(), 2)
        self.assertEqual(Person.objects.count(), 3)
        self.assertEqual(first.data['relationship']['notes'], 'Recorded parentage')
        self.assertEqual(len(first.data['additional_relationships']), 1)
        data['relationship_notes'] = 'Changed'
        self.assertEqual(self.client.post(url, data, format='json', HTTP_IDEMPOTENCY_KEY='compound-link').status_code, 409)

    def test_malformed_relative_ids_and_self_links_are_rejected(self):
        url = f'/api/people/{self.source.pk}/create_relative/'
        for field in ('existing_person_id', 'co_parent_id'):
            response = self.client.post(url, {'role':'child', 'person':{}, field:'bad'}, format='json')
            self.assertEqual(response.status_code, 400, response.data)
        response = self.client.post(url, {'role':'sibling', 'person':{}, 'existing_person_id':self.source.pk}, format='json')
        self.assertEqual(response.status_code, 400, response.data)
        self.assertEqual(Relationship.objects.count(), 0)

    def test_former_spouse_is_retained_but_not_returned_as_current_spouse(self):
        other = Person.objects.create(family_tree=self.tree, first_name='Former', last_name='Partner', gender='O')
        link = Relationship.objects.create(person1=self.source, person2=other, relationship_type='SPOUSE')
        response = self.client.patch(f'/api/relationships/{link.pk}/', {'is_current':False, 'notes':'Ended', 'start_date':'2000-01-01', 'end_date':'2010-01-01'}, format='json')
        self.assertEqual(response.status_code, 200, response.data)
        self.assertEqual(self.source.get_spouses().count(), 0)
        link.refresh_from_db()
        self.assertEqual(link.notes, 'Ended')
        self.assertEqual(Relationship.objects.count(), 1)

    def test_large_graph_load_has_bounded_queries_and_no_quadratic_family_nesting(self):
        children = Person.objects.bulk_create([Person(family_tree=self.tree, first_name=f'Child{i}', last_name='Scale', gender='O') for i in range(2000)])
        Relationship.objects.bulk_create([Relationship(person1=self.source, person2=p, relationship_type='PARENT') for p in children])
        with CaptureQueriesContext(connection) as person_queries:
            response = self.client.get(f'/api/people/?family_tree={self.tree.pk}&compact=1')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 2001)
        self.assertNotIn('siblings', response.data[0])
        self.assertLess(len(response.content), 3_000_000)
        self.assertLessEqual(len(person_queries), 5)
        with CaptureQueriesContext(connection) as link_queries:
            links = self.client.get(f'/api/relationships/?family_tree={self.tree.pk}')
        self.assertEqual(len(links.data), 2000)
        self.assertLessEqual(len(link_queries), 5)

