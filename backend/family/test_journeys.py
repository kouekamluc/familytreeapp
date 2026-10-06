from unittest.mock import patch
from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework.exceptions import ValidationError
from family.models import FamilyTree, Person, Relationship


class RelativeJourneyTests(TestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(username='owner', password='Test-pass-123')
        self.tree = FamilyTree.objects.create(name='Family', owner=self.user)
        self.person = Person.objects.create(family_tree=self.tree, first_name='Source', last_name='Person')
        self.client = APIClient()
        self.client.force_authenticate(self.user)
        self.url = f'/api/people/{self.person.pk}/create_relative/'

    def test_parent_direction_and_tree_binding(self):
        response = self.client.post(self.url, {'role': 'parent', 'person': {
            'first_name': 'Parent', 'last_name': 'Person', 'family_tree': 999}}, format='json')
        self.assertEqual(response.status_code, 201, response.data)
        relative = Person.objects.get(pk=response.data['person']['id'])
        self.assertEqual(relative.family_tree_id, self.tree.pk)
        self.assertTrue(Relationship.objects.filter(person1=relative, person2=self.person,
                                                    relationship_type='PARENT').exists())

    def test_typed_parentage_keeps_direction_and_reuses_profiles(self):
        for kind in ('ADOPTED', 'STEP'):
            with self.subTest(kind=kind):
                relative = Person.objects.create(family_tree=self.tree, first_name=kind, last_name='Parent')
                response = self.client.post(self.url, {'role': 'parent', 'relationship_type': kind,
                    'person': {}, 'existing_person_id': relative.pk}, format='json')
                self.assertEqual(response.status_code, 201, response.data)
                self.assertEqual(response.data['person']['id'], relative.pk)
                self.assertTrue(Relationship.objects.filter(person1=relative, person2=self.person, relationship_type=kind).exists())
        self.assertEqual(Person.objects.count(), 3)

    def test_typed_child_creates_both_parent_links_atomically(self):
        co_parent = Person.objects.create(family_tree=self.tree, first_name='Other', last_name='Parent')
        response = self.client.post(self.url, {'role': 'child', 'relationship_type': 'ADOPTED',
            'co_parent_id': co_parent.pk, 'person': {'first_name': 'Child', 'last_name': 'Family'}}, format='json')
        self.assertEqual(response.status_code, 201, response.data)
        child = Person.objects.get(pk=response.data['person']['id'])
        self.assertEqual(child.generation_tier, self.person.generation_tier + 1)
        links = Relationship.objects.filter(person2=child)
        self.assertEqual(set(links.values_list('person1_id', flat=True)), {self.person.pk, co_parent.pk})
        self.assertEqual(set(links.values_list('relationship_type', flat=True)), {'ADOPTED'})

    def test_invalid_parentage_choices_do_not_create_records(self):
        for role, kind in [('spouse', 'ADOPTED'), ('sibling', 'STEP'), ('child', 'UNKNOWN'), ('child', []), ([], 'PARENT')]:
            response = self.client.post(self.url, {'role': role, 'relationship_type': kind,
                'person': {'first_name': 'Invalid', 'last_name': 'Record'}}, format='json')
            self.assertEqual(response.status_code, 400, response.data)
        self.assertEqual(Person.objects.count(), 1)
        self.assertEqual(Relationship.objects.count(), 0)

    def test_unknown_source_generation_does_not_block_a_relative(self):
        self.person.generation_tier = None
        self.person.save()
        response = self.client.post(self.url, {'role': 'parent', 'person': {'first_name': 'Parent', 'last_name': 'Family'}}, format='json')
        self.assertEqual(response.status_code, 201, response.data)
        self.assertEqual(response.data['person']['generation_tier'], 0)

    def test_relationship_failure_rolls_back_person(self):
        with patch('family.views.RelationshipSerializer.is_valid', side_effect=ValidationError('Invalid link')):
            response = self.client.post(self.url, {'role': 'child', 'person': {
                'first_name': 'Child', 'last_name': 'Person'}}, format='json')
        self.assertEqual(response.status_code, 400)
        self.assertEqual(Person.objects.count(), 1)
        self.assertEqual(Relationship.objects.count(), 0)

    def test_stranger_cannot_create_relative(self):
        stranger = get_user_model().objects.create_user(username='stranger', email='stranger@example.com')
        self.client.force_authenticate(stranger)
        response = self.client.post(self.url, {'role': 'child', 'person': {
            'first_name': 'Child', 'last_name': 'Person'}}, format='json')
        self.assertIn(response.status_code, (403, 404))
        self.assertEqual(Person.objects.count(), 1)

    def test_invalid_role_creates_nothing(self):
        response = self.client.post(self.url, {'role': 'unknown', 'person': {
            'first_name': 'Child', 'last_name': 'Person'}}, format='json')
        self.assertEqual(response.status_code, 400)
        self.assertEqual(Person.objects.count(), 1)


    def test_notes_patch_and_invalid_partial_self_link(self):
        link = Relationship.objects.create(person1=self.person, person2=Person.objects.create(
            family_tree=self.tree, first_name='Child', last_name='Person', gender='F'), relationship_type='PARENT')
        response = self.client.patch(f'/api/relationships/{link.pk}/', {'notes': 'Updated'}, format='json')
        self.assertEqual(response.status_code, 200)
        response = self.client.patch(f'/api/relationships/{link.pk}/', {'person2': self.person.pk}, format='json')
        self.assertEqual(response.status_code, 400)
        link.refresh_from_db()
        self.assertNotEqual(link.person1_id, link.person2_id)

    def test_invalid_life_dates_rejected(self):
        response = self.client.patch(f'/api/people/{self.person.pk}/', {
            'date_of_birth': '2000-01-01', 'date_of_death': '1990-01-01', 'is_living': False}, format='json')
        self.assertEqual(response.status_code, 400)

    def test_admin_model_validation_and_event_patch_share_date_checks(self):
        from datetime import date
        from django.core.exceptions import ValidationError as ModelValidationError
        from family.models import Event
        self.person.date_of_birth = date(1980,1,1); self.person.save()
        child = Person.objects.create(family_tree=self.tree,first_name='Child',last_name='Person',gender='O',date_of_birth=date(2000,1,1))
        Relationship.objects.create(person1=self.person,person2=child,relationship_type='PARENT')
        self.person.date_of_birth = date(2010,1,1)
        with self.assertRaises(ModelValidationError): self.person.full_clean()
        self.person.refresh_from_db()
        event = Event.objects.create(person=self.person,event_type='BIRTH',date=self.person.date_of_birth,description='Recorded')
        response = self.client.patch(f'/api/events/{event.pk}/',{'date':'1990-01-01'},format='json')
        self.assertEqual(response.status_code,400)
        event.refresh_from_db(); self.assertEqual(event.date,date(1980,1,1))

    def test_idempotent_relative_retry(self):
        data = {'role': 'child', 'person': {'first_name': 'Child', 'last_name': 'Person', 'date_of_birth': '2020-01-01'}}
        first = self.client.post(self.url, data, format='json', HTTP_IDEMPOTENCY_KEY='same-operation')
        second = self.client.post(self.url, data, format='json', HTTP_IDEMPOTENCY_KEY='same-operation')
        self.assertEqual(first.status_code, 201, first.data)
        self.assertEqual(second.data['person']['id'], first.data['person']['id'])
        self.assertEqual(Person.objects.count(), 2)
        data['person']['first_name'] = 'Different'
        response = self.client.post(self.url, data, format='json', HTTP_IDEMPOTENCY_KEY='same-operation')
        self.assertEqual(response.status_code, 409)

    def test_import_rejects_duplicates_self_links_cycles_and_wrong_models(self):
        import json
        from django.core.files.uploadedfile import SimpleUploadedFile
        def entry(pk, name):
            return {'model': 'family.person', 'pk': pk, 'fields': {'first_name': name, 'last_name': 'Person', 'gender': 'O'}}
        def upload(data):
            return self.client.post('/api/data/import/', {'tree_id': self.tree.pk,
                'file': SimpleUploadedFile('import.json', json.dumps(data).encode(), 'application/json')}, format='multipart')
        cases = [
            {'people': [entry(1, 'A'), entry(1, 'B')], 'relationships': []},
            {'people': [entry(1, 'A')], 'relationships': [{'model':'family.relationship','pk':1,'fields':{'person1':1,'person2':1,'relationship_type':'PARENT'}}]},
            {'people': [entry(1, 'A'),entry(2, 'B')], 'relationships': [{'model':'family.relationship','pk':i,'fields':{'person1':a,'person2':b,'relationship_type':'PARENT'}} for i,a,b in [(1,1,2),(2,2,1)]]},
            {'people': [{'model':'users.user','pk':1,'fields':{}}], 'relationships': []},
        ]
        for data in cases:
            with self.subTest(data=data):
                self.assertEqual(upload(data).status_code, 400)
                self.assertEqual(Person.objects.count(), 1)
