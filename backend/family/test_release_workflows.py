from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient
from .models import FamilyTree, Person, Relationship
from .joining import ancestry_candidates
from .models import ContentReport, TreeMembership
from django.core.exceptions import ValidationError


class ReleaseWorkflowTests(TestCase):
    def setUp(self):
        User = get_user_model()
        self.owner = User.objects.create_user(username='private-owner', email='private@example.test')
        self.outsider = User.objects.create_user(username='private-outsider', email='outside@example.test')
        self.tree = FamilyTree.objects.create(name='Legacy public', owner=self.owner, is_public=True, discovery_enabled=True)
        self.parent = Person.objects.create(family_tree=self.tree, first_name='Pául', last_name='Family', gender='O')
        self.gp = Person.objects.create(family_tree=self.tree, first_name='Máriam', last_name='Family', gender='O')
        self.link = Relationship.objects.create(person1=self.gp, person2=self.parent, relationship_type='PARENT')
        self.client = APIClient()

    def test_legacy_public_flag_grants_no_record_access(self):
        for user in (None, self.outsider):
            self.client.force_authenticate(user)
            self.assertEqual(self.client.get('/api/trees/').data['results'], [])
            self.assertEqual(self.client.get(f'/api/trees/{self.tree.pk}/').status_code, 404)
            self.assertEqual(self.client.get('/api/people/').data, [])
            self.assertEqual(self.client.get('/api/relationships/').data, [])
        self.client.force_authenticate(self.owner)
        self.assertFalse(self.client.get(f'/api/trees/{self.tree.pk}/').data['is_public'])
        self.assertEqual(self.client.patch(f'/api/trees/{self.tree.pk}/', {'is_public': True}, format='json').status_code, 400)
        self.tree.refresh_from_db()
        self.assertTrue(self.tree.is_public)  # Preserve stored historical intent.

    def test_matching_after_ten_thousand_unrelated_links_and_name_corrections(self):
        self.link.delete()
        people = Person.objects.bulk_create([Person(family_tree=self.tree, first_name=f'Unrelated{i}', last_name='Fixture', gender='O') for i in range(10001)])
        Relationship.objects.bulk_create([Relationship(person1=self.gp, person2=p, relationship_type='PARENT') for p in people])
        Relationship.objects.create(person1=self.gp, person2=self.parent, relationship_type='PARENT')
        facts = {'parent_name': '  PAUL FAMILY ', 'grandparent_name': 'mariam family'}
        self.assertEqual(len(ancestry_candidates(self.outsider, facts)), 1)

        self.parent.first_name = 'Changed'
        self.parent.save(update_fields=['first_name'])
        self.assertEqual(ancestry_candidates(self.outsider, facts), [])
        self.parent.first_name = 'Paul'
        Person.objects.bulk_update([self.parent], ['first_name'])
        self.assertEqual(len(ancestry_candidates(self.outsider, facts)), 1)

    def test_viewer_report_receipt_review_and_privacy(self):
        payload = {'person_id': self.parent.pk, 'reason': 'PRIVACY', 'details': 'Please review the portrait.', 'request_key': 'same-report'}
        self.client.force_authenticate(self.outsider)
        self.assertEqual(self.client.post('/api/content-reports/', payload, format='json').status_code, 404)
        self.tree.members.add(self.outsider)
        TreeMembership.objects.create(tree=self.tree, user=self.outsider, role='VIEWER')
        first = self.client.post('/api/content-reports/', payload, format='json')
        again = self.client.post('/api/content-reports/', payload, format='json')
        self.assertEqual(first.status_code, 201, first.data)
        self.assertEqual(first.data['id'], again.data['id'])
        self.assertEqual(ContentReport.objects.count(), 1)
        self.assertEqual(self.client.post('/api/content-reports/', {**payload, 'details': 'Different request'}, format='json').status_code, 409)
        self.assertEqual(self.client.patch(f'/api/content-reports/{first.data["id"]}/', {'status': 'RESOLVED'}, format='json').status_code, 404)
        self.client.force_authenticate(self.owner)
        self.assertEqual(self.client.get('/api/content-reports/').data['reports'], [])
        report = ContentReport.objects.get(pk=first.data['id'])
        report.status = 'RESOLVED'
        with self.assertRaises(ValidationError): report.full_clean()
        report.response = 'The portrait has been removed.'
        report.full_clean(); report.save()
        self.client.force_authenticate(self.outsider)
        self.tree.members.remove(self.outsider)
        receipt = self.client.get('/api/content-reports/').data['reports'][0]
        self.assertEqual((receipt['status'], receipt['response']), ('RESOLVED', report.response))

    def test_pending_status_counts_include_only_owned_families(self):
        from .models import JoinRequest
        JoinRequest.objects.create(tree=self.tree, applicant=self.outsider, anchor=self.parent, mode='CHILD', person_data={})
        self.client.force_authenticate(self.owner)
        counts = self.client.get('/api/family-access/').data
        self.assertEqual((counts['pending_reviews'], counts['pending_requests']), (1, 0))
        self.client.force_authenticate(self.outsider)
        counts = self.client.get('/api/family-access/').data
        self.assertEqual((counts['pending_reviews'], counts['pending_requests']), (0, 1))

    def test_retried_family_and_person_creation_do_not_duplicate_and_conflicting_keys_fail(self):
        self.client.force_authenticate(self.owner)
        data = {'name': 'One new family', 'description': 'Synthetic receipt'}
        first = self.client.post('/api/trees/', data, format='json', HTTP_IDEMPOTENCY_KEY='family-create')
        replay = self.client.post('/api/trees/', data, format='json', HTTP_IDEMPOTENCY_KEY='family-create')
        self.assertEqual(first.status_code, 201, first.data)
        self.assertEqual(first.data['id'], replay.data['id'])
        self.assertEqual(FamilyTree.objects.filter(name=data['name']).count(), 1)
        person = {'family_tree': first.data['id'], 'first_name': 'One', 'last_name': 'New record', 'gender': 'O'}
        created = self.client.post('/api/people/', person, format='json', HTTP_IDEMPOTENCY_KEY='person-create')
        self.client.patch(f'/api/people/{created.data["id"]}/', {'birth_place': 'A later correction'}, format='json')
        replay = self.client.post('/api/people/', person, format='json', HTTP_IDEMPOTENCY_KEY='person-create')
        self.assertEqual(created.data['id'], replay.data['id'])
        self.assertEqual(replay.data['birth_place'], 'A later correction')
        self.assertEqual(Person.objects.filter(family_tree_id=first.data['id']).count(), 1)
        conflict = self.client.post('/api/people/', {**person, 'first_name': 'Different'}, format='json', HTTP_IDEMPOTENCY_KEY='person-create')
        self.assertEqual(conflict.status_code, 409)
        self.client.delete(f'/api/people/{created.data["id"]}/')
        removed = self.client.post('/api/people/', person, format='json', HTTP_IDEMPOTENCY_KEY='person-create')
        self.assertEqual(removed.status_code, 409)
        self.assertEqual(Person.objects.filter(family_tree_id=first.data['id']).count(), 0)
