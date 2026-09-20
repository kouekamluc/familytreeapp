from datetime import timedelta
from django.test import TestCase
from django.utils import timezone
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status

from family.models import FamilyTree, Person, Relationship
from users.models import HeritageKey
from backup.services import BackupService

User = get_user_model()


class SecurityAndIntegrityTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        
        # User A (Royal Patriarch / Owner of Tree A)
        self.user_a = User.objects.create_user(
            username='patriarch_a',
            email='patriarch_a@kkevo.org',
            password='SecurePassword123!',
            first_name='Kamgou',
            last_name='Kkevo'
        )
        self.tree_a = FamilyTree.objects.create(
            name="Dynastie Kamgou Royale",
            owner=self.user_a,
            is_public=False
        )
        self.person_a1 = Person.objects.create(
            family_tree=self.tree_a,
            first_name='Kamgou',
            last_name='Kkevo',
            gender='M',
            traditional_name='Fo Kamgou II',
            generation_tier=1
        )
        self.person_a2 = Person.objects.create(
            family_tree=self.tree_a,
            first_name='Hélène',
            last_name='Kkevo',
            gender='F',
            traditional_name='Mafo Hélène',
            generation_tier=1
        )

        # User B (Unrelated User / Owner of Tree B)
        self.user_b = User.objects.create_user(
            username='stranger_b',
            email='stranger_b@kkevo.org',
            password='AnotherPassword123!',
            first_name='John',
            last_name='Doe'
        )
        self.tree_b = FamilyTree.objects.create(
            name="Doe Family Tree",
            owner=self.user_b,
            is_public=False
        )
        self.person_b1 = Person.objects.create(
            family_tree=self.tree_b,
            first_name='John',
            last_name='Doe',
            gender='M',
            generation_tier=1
        )

    # --- 1. Tree Access & Data Isolation ---

    def test_anonymous_cannot_access_private_tree(self):
        """Anonymous users must not be able to retrieve private family trees."""
        response = self.client.get(f'/api/trees/{self.tree_a.id}/')
        self.assertIn(response.status_code, [status.HTTP_401_UNAUTHORIZED, status.HTTP_404_NOT_FOUND])

    def test_unrelated_user_cannot_view_private_tree(self):
        """User B cannot view User A's private family tree."""
        self.client.force_authenticate(user=self.user_b)
        response = self.client.get(f'/api/trees/{self.tree_a.id}/')
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_unrelated_user_cannot_read_private_persons(self):
        """Passing ?tree_id=UserA_Tree must NOT leak persons to User B."""
        self.client.force_authenticate(user=self.user_b)
        response = self.client.get(f'/api/people/?tree_id={self.tree_a.id}')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Should be empty because User B does not have access to Tree A
        self.assertEqual(len(response.data), 0)

    def test_unrelated_user_cannot_create_person_in_other_tree(self):
        """User B cannot inject individuals into User A's family tree."""
        self.client.force_authenticate(user=self.user_b)
        payload = {
            'family_tree': self.tree_a.id,
            'first_name': 'Intruder',
            'last_name': 'Malicious',
            'gender': 'M',
            'generation_tier': 2
        }
        response = self.client.post('/api/people/', payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        self.assertFalse(Person.objects.filter(first_name='Intruder').exists())

    # --- 2. Cross-Tree Integrity & Anti-Tampering ---

    def test_cross_tree_relationship_prohibited(self):
        """Relationships between persons from different trees must be rejected."""
        self.client.force_authenticate(user=self.user_a)
        payload = {
            'person1': self.person_a1.id,
            'person2': self.person_b1.id,
            'relationship_type': 'SPOUSE'
        }
        response = self.client.post('/api/relationships/', payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        # Verify person_b1 tree was not altered or transferred
        self.person_b1.refresh_from_db()
        self.assertEqual(self.person_b1.family_tree_id, self.tree_b.id)
        self.assertEqual(Relationship.objects.count(), 0)

    # --- 3. Heritage Key Security ---

    def test_expired_heritage_key_rejected(self):
        """Expired Heritage Keys must be rejected immediately."""
        expired_key = HeritageKey.objects.create(
            user=self.user_a,
            key='KKEVO-EXPIRED-TEST-0001',
            family_tree=self.tree_a,
            is_active=True,
            expires_at=timezone.now() - timedelta(days=1)
        )
        response = self.client.post('/api/users/heritage-key/login/', {'key': expired_key.key}, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_revoked_heritage_key_rejected(self):
        """Deactivated or revoked Heritage Keys must be rejected."""
        revoked_key = HeritageKey.objects.create(
            user=self.user_a,
            key='KKEVO-REVOKED-TEST-0002',
            family_tree=self.tree_a,
            is_active=False
        )
        response = self.client.post('/api/users/heritage-key/login/', {'key': revoked_key.key}, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    # --- 4. Scoped Export Protection ---

    def test_export_scoped_to_authorized_tree(self):
        """User B cannot export User A's private tree data."""
        self.client.force_authenticate(user=self.user_b)
        response = self.client.get(f'/api/data/export/?tree_id={self.tree_a.id}')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    # --- 5. Transactional Restore Rehearsal ---

    def test_transactional_restore_rehearsal_failure_causes_no_data_loss(self):
        """
        Restore Rehearsal:
        If a corrupted or invalid backup file fails during restore,
        the entire transaction must roll back and preserve 100% of existing data.
        """
        backup_service = BackupService()
        
        initial_tree_count = FamilyTree.objects.count()
        initial_person_count = Person.objects.count()
        
        # Create a valid backup first
        backup = backup_service.create_backup(user=self.user_a)
        self.assertTrue(backup.file_path)
        
        # Corrupt the backup file content to force an intentional failure during restoration
        import json
        with open(backup.file_path, 'r') as f:
            data = json.load(f)
        
        # Remove a required section to simulate corruption
        del data['relationships']
        with open(backup.file_path, 'w') as f:
            json.dump(data, f)
        
        # Attempt to restore the corrupted backup
        with self.assertRaises(Exception):
            backup_service.restore_backup(backup.id)
            
        # Verify that original database records are completely intact!
        self.assertEqual(FamilyTree.objects.count(), initial_tree_count)
        self.assertEqual(Person.objects.count(), initial_person_count)
        self.assertTrue(Person.objects.filter(id=self.person_a1.id).exists())
        self.assertTrue(Person.objects.filter(id=self.person_b1.id).exists())
