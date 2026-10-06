import json
from unittest.mock import patch
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from rest_framework.test import APIClient
from family.models import FamilyTree, Person


class TransferRecoveryTests(TestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(username='transfer-audit', email='transfer@example.test')
        self.tree = FamilyTree.objects.create(name='Synthetic export', owner=self.user)
        self.client = APIClient()
        self.client.force_authenticate(self.user)

    def test_invalid_destination_is_a_validation_error(self):
        self.assertEqual(self.client.get('/api/data/export/?tree_id=invalid').status_code, 400)
        response = self.client.post('/api/data/import/', {'tree_id':'invalid','file':SimpleUploadedFile('synthetic.json', b'{"people":[],"relationships":[]}', content_type='application/json')})
        self.assertEqual(response.status_code, 400)
        self.assertEqual(Person.objects.count(), 0)

    def test_unexpected_export_failure_exposes_no_exception_content(self):
        with patch('data_management.views.serializers.serialize', side_effect=RuntimeError('private deployment detail')):
            with self.assertLogs('data_management.views', level='ERROR') as logs:
                response = self.client.get(f'/api/data/export/?tree_id={self.tree.pk}')
        self.assertEqual(response.status_code, 500)
        self.assertNotIn('private deployment detail', response.content.decode())
        self.assertNotIn('private deployment detail', str(logs.output))

    def test_unexpected_import_failure_rolls_back_and_allows_retry(self):
        payload = json.dumps({'people':[{'pk':1,'fields':{'first_name':'Synthetic','last_name':'Person','gender':'O'}}],'relationships':[]}).encode()
        def submit():
            return self.client.post('/api/data/import/', {'tree_id':self.tree.pk,'file':SimpleUploadedFile('synthetic.json',payload,content_type='application/json')}, HTTP_IDEMPOTENCY_KEY='interrupted-import')
        with patch('family.models.Person.save', side_effect=RuntimeError('private storage detail')):
            with self.assertLogs('data_management.views', level='ERROR'):
                response = submit()
        self.assertEqual(response.status_code, 500)
        self.assertNotIn('private storage detail', response.content.decode())
        self.assertEqual(Person.objects.count(), 0)
        self.assertEqual(submit().status_code, 201)
        self.assertEqual(submit().status_code, 201)
        self.assertEqual(Person.objects.count(), 1)
