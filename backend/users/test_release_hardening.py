from unittest.mock import patch
from django.contrib.auth import authenticate, get_user_model
from django.core.cache import cache
from django.test import TestCase
from rest_framework.test import APIClient


class ReleaseAccountHardeningTests(TestCase):
    def setUp(self):
        cache.clear()
        self.user = get_user_model().objects.create_user(username='hardened-account', email='hardened@example.test', password='Synthetic-Password-482!')
        self.client = APIClient()

    def test_unknown_and_wrong_password_take_the_authentication_path_and_return_the_same_error(self):
        with patch('users.views.authenticate', wraps=authenticate) as authenticate_call:
            with self.assertNoLogs('users.views', level='DEBUG'):
                unknown = self.client.post('/api/auth/login/', {'username': 'unknown-account', 'password': 'incorrect'}, format='json')
                wrong = self.client.post('/api/auth/login/', {'username': self.user.username, 'password': 'incorrect'}, format='json')
            self.assertEqual(authenticate_call.call_count, 2)
        self.assertEqual(unknown.status_code, 401)
        self.assertEqual(unknown.data, wrong.data)

    def test_non_object_account_requests_are_rejected_without_server_errors(self):
        self.client.force_authenticate(self.user)
        self.assertEqual(self.client.post('/api/auth/account/', ['invalid'], format='json').status_code, 400)
        self.client.force_authenticate(None)
        self.assertEqual(self.client.post('/api/auth/recovery/', ['invalid'], format='json').status_code, 400)
