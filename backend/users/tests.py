from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.core.cache import cache
from datetime import timedelta
from .models import HeritageKey

User = get_user_model()

class HeritageKeyAuthTests(TestCase):
    def setUp(self):
        cache.clear()
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='dynastycurator',
            email='curator@kkevo.org',
            password='Password123!',
            first_name='Kevine',
            last_name='Kkevo'
        )
        self.heritage_key = HeritageKey.objects.create(
            user=self.user,
            key='KKEVO-ROYAL-TEST-9999',
            name='Sacred Test Royal Key',
            role='CURATOR',
            is_active=True
        )

    def test_heritage_key_generation(self):
        """Test random royal key string generation format."""
        generated = HeritageKey.generate_royal_key_string()
        self.assertTrue(generated.startswith('KKEVO-ROYAL-'))
        parts = generated.split('-')
        self.assertEqual(len(parts), 4)
        self.assertEqual(len(parts[2]), 8)
        self.assertEqual(len(parts[3]), 8)

    def test_login_with_valid_heritage_key(self):
        """Test successful authentication using a valid Heritage Key."""
        url = reverse('heritage_key_login')
        response = self.client.post(url, {'key': 'KKEVO-ROYAL-TEST-9999'}, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)
        self.assertIn('user', response.data)
        self.assertEqual(response.data['user']['username'], 'dynastycurator')
        self.assertEqual(response.data['heritage_key']['key'], 'KKEVO-ROYAL-TEST-9999')

        # Check that last_used_at and usage_count were updated
        self.heritage_key.refresh_from_db()
        self.assertEqual(self.heritage_key.usage_count, 1)
        self.assertIsNotNone(self.heritage_key.last_used_at)

    def test_login_with_case_insensitive_key(self):
        """Test that Heritage Key authentication is case-insensitive and trims whitespace."""
        url = reverse('heritage_key_login')
        response = self.client.post(url, {'key': '  kkevo-royal-test-9999  '}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)

    def test_login_with_invalid_heritage_key(self):
        """Test that invalid Heritage Key is rejected with an error message."""
        url = reverse('heritage_key_login')
        response = self.client.post(url, {'key': 'INVALID-KEY-1234'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)

    def test_login_with_inactive_heritage_key(self):
        """Test that revoked/inactive Heritage Key cannot be used."""
        self.heritage_key.is_active = False
        self.heritage_key.save()

        url = reverse('heritage_key_login')
        response = self.client.post(url, {'key': 'KKEVO-ROYAL-TEST-9999'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_login_with_expired_heritage_key(self):
        """Test that expired Heritage Key cannot be used."""
        self.heritage_key.expires_at = timezone.now() - timedelta(days=1)
        self.heritage_key.save()

        url = reverse('heritage_key_login')
        response = self.client.post(url, {'key': 'KKEVO-ROYAL-TEST-9999'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_authenticated_user_heritage_key_management(self):
        """Test listing, generating, and revoking heritage keys for authenticated user."""
        self.client.force_authenticate(user=self.user)

        # 1. Get my keys
        me_url = reverse('heritage_key_me')
        response = self.client.get(me_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(len(response.data) >= 1)

        # 2. Generate a new key
        gen_url = reverse('heritage_key_generate')
        gen_response = self.client.post(gen_url, {'name': 'Elder Council Key', 'role': 'ROYAL_PATRIARCH'}, format='json')
        self.assertEqual(gen_response.status_code, status.HTTP_201_CREATED)
        new_key_id = gen_response.data['id']
        new_key_str = gen_response.data['key']

        # 3. Revoke key
        revoke_url = reverse('heritage_key_revoke')
        revoke_response = self.client.post(revoke_url, {'key_id': new_key_id}, format='json')
        self.assertEqual(revoke_response.status_code, status.HTTP_200_OK)

        # Verify key is inactive
        revoked_key = HeritageKey.objects.get(id=new_key_id)
        self.assertFalse(revoked_key.is_active)

