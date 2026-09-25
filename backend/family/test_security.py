from datetime import timedelta
import json
import os
from django.test import TestCase
from django.utils import timezone
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status

from family.models import FamilyTree, Person, Relationship
from users.models import HeritageKey
from backup.services import BackupService
from django.core.files.uploadedfile import SimpleUploadedFile
from django.core.files.base import ContentFile
from django.core.files.storage import default_storage
from family.models import Event

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

    def test_person_cannot_be_moved_into_another_tree(self):
        self.client.force_authenticate(user=self.user_b)
        response = self.client.patch(f'/api/people/{self.person_b1.id}/',
                                     {'family_tree': self.tree_a.id}, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.person_b1.refresh_from_db()
        self.assertEqual(self.person_b1.family_tree_id, self.tree_b.id)

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

    def test_duplicate_relationship_does_not_reveal_private_people(self):
        Relationship.objects.create(person1=self.person_a1, person2=self.person_a2,
                                    relationship_type='SPOUSE')
        self.client.force_authenticate(user=self.user_b)
        response = self.client.post('/api/relationships/', {
            'person1': self.person_a1.id, 'person2': self.person_a2.id,
            'relationship_type': 'SPOUSE'}, format='json')
        self.assertNotEqual(response.status_code, status.HTTP_200_OK)
        self.assertNotIn('person1_details', response.data)

    def test_event_writes_are_scoped_and_owner_can_read_detail(self):
        self.client.force_authenticate(user=self.user_b)
        response = self.client.post('/api/events/', {
            'person': self.person_a1.id, 'event_type': 'OTHER',
            'date': '2020-01-01', 'description': 'Intrusion'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        self.assertFalse(Event.objects.exists())
        event = Event.objects.create(person=self.person_a1, event_type='OTHER',
                                     date='2020-01-01', description='Family history')
        self.client.force_authenticate(user=self.user_a)
        self.assertEqual(self.client.get(f'/api/events/{event.id}/').status_code,
                         status.HTTP_200_OK)

    def test_tree_detail_is_serializable(self):
        self.client.force_authenticate(user=self.user_a)
        response = self.client.get(f'/api/trees/{self.tree_a.id}/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['id'], self.tree_a.id)

    def test_profile_picture_uses_short_lived_link_without_public_media_route(self):
        self.person_a1.profile_picture.save('access-test.png', ContentFile(b'private-image'), save=True)
        name = self.person_a1.profile_picture.name
        try:
            self.assertEqual(self.client.get('/media/' + name).status_code, status.HTTP_404_NOT_FOUND)
            self.client.force_authenticate(user=self.user_a)
            response = self.client.get(f'/api/people/{self.person_a1.id}/')
            self.assertEqual(response.status_code, status.HTTP_200_OK)
            signed_url = response.data['profile_picture']
            self.assertIn('/api/files/?token=', signed_url)
            self.client.force_authenticate(user=None)
            download_res = self.client.get(signed_url)
            self.assertEqual(download_res.status_code, status.HTTP_200_OK)
            for closer in getattr(download_res, '_resource_closers', []):
                closer()
            self.assertEqual(self.client.get(signed_url + 'changed').status_code, status.HTTP_404_NOT_FOUND)
        finally:
            default_storage.delete(name)

    def test_member_cannot_import_into_tree_they_do_not_own(self):
        self.tree_a.members.add(self.user_b)
        self.client.force_authenticate(user=self.user_b)
        upload = SimpleUploadedFile('tree.json', b'{"people":[],"relationships":[]}',
                                    content_type='application/json')
        response = self.client.post(f'/api/data/import/?tree_id={self.tree_a.id}',
                                    {'file': upload}, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

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

    def test_cannot_generate_key_for_another_tree(self):
        self.client.force_authenticate(user=self.user_b)
        response = self.client.post('/api/users/heritage-key/generate/',
                                    {'family_tree': self.tree_a.id}, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_registration_uses_submitted_password(self):
        response = APIClient().post('/api/users/register/', {
            'username': 'new_relative', 'email': 'relative@example.test',
            'first_name': 'New', 'last_name': 'Relative',
            'password': 'StrongPassword123!', 'password2': 'StrongPassword123!'
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(User.objects.get(username='new_relative').check_password('StrongPassword123!'))

    def test_valid_json_import_and_invalid_reference_rollback(self):
        self.client.force_authenticate(user=self.user_b)
        data = {'people': [{'pk': 10, 'fields': {'first_name': 'New', 'last_name': 'Relative',
                                                'gender': 'F'}}], 'relationships': []}
        upload = SimpleUploadedFile('tree.json', json.dumps(data).encode(),
                                    content_type='application/json')
        response = self.client.post(f'/api/data/import/?tree_id={self.tree_b.id}',
                                    {'file': upload}, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(Person.objects.filter(family_tree=self.tree_b, first_name='New').exists())
        before = Person.objects.count()
        data['relationships'] = [{'fields': {'person1': 10, 'person2': 999,
                                              'relationship_type': 'PARENT'}}]
        upload = SimpleUploadedFile('invalid.json', json.dumps(data).encode(),
                                    content_type='application/json')
        response = self.client.post(f'/api/data/import/?tree_id={self.tree_b.id}',
                                    {'file': upload}, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(Person.objects.count(), before)

    def test_backup_actions_require_admin(self):
        self.client.force_authenticate(user=self.user_b)
        self.assertEqual(self.client.get('/api/backup/backups/').status_code,
                         status.HTTP_403_FORBIDDEN)
        self.assertEqual(self.client.post('/api/backup/backups/create_backup/').status_code,
                         status.HTTP_403_FORBIDDEN)

    def test_backup_round_trip_preserves_tree_and_relationships(self):
        relationship = Relationship.objects.create(person1=self.person_a1,
                                                    person2=self.person_a2,
                                                    relationship_type='SPOUSE')
        service = BackupService()
        try:
            backup = service.create_backup(user=self.user_a)
            self.person_a1.first_name = 'Changed'
            self.person_a1.save(update_fields=['first_name'])
            service.restore_backup(backup.id)
        finally:
            if 'backup' in locals() and os.path.exists(backup.file_path):
                os.remove(backup.file_path)
        self.assertEqual(Person.objects.get(id=self.person_a1.id).first_name, 'Kamgou')
        self.assertTrue(Relationship.objects.filter(id=relationship.id).exists())

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
