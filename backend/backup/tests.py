import hashlib
import json
from pathlib import Path
import tempfile
from unittest.mock import patch, Mock
import zipfile

from django.contrib.auth import get_user_model
from django.test import TestCase, override_settings
from family.models import FamilyTree, Person
from users.models import HeritageKey
from .models import Backup
from .services import BackupService


class BackupSafetyTests(TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='familytree-backup-test-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.override = override_settings(BASE_DIR=self.root, MEDIA_ROOT=self.root / 'media')
        self.override.enable()
        self.addCleanup(self.override.disable)
        self.user = get_user_model().objects.create_user(username='backup-owner', email='backup@example.test')
        self.tree = FamilyTree.objects.create(name='Private', owner=self.user)
        self.person = Person.objects.create(family_tree=self.tree, first_name='Before', last_name='Backup', gender='O', profile_picture='portraits/a.png')
        self.key = HeritageKey.objects.create(user=self.user, key='AUDIT-KEY', family_tree=self.tree, person=self.person)
        (self.root / 'media/portraits').mkdir(parents=True)
        (self.root / 'media/portraits/a.png').write_bytes(b'backup-photo')
        self.service = BackupService()

    def tamper(self, backup, change):
        with zipfile.ZipFile(backup.file_path) as archive:
            contents = {name: archive.read(name) for name in archive.namelist()}
        change(contents)
        with zipfile.ZipFile(backup.file_path, 'w') as archive:
            for name, content in contents.items():
                archive.writestr(name, content)

    def test_version_six_without_name_index_restores_and_reports_survive_current_backup(self):
        from family.models import ContentReport
        report = ContentReport.objects.create(reporter=self.user, tree=self.tree, person=self.person,
            reason='PRIVACY', details='Synthetic review', request_key='backup-report')
        current = self.service.create_backup(self.user)
        report.delete()
        self.service.restore_backup(current.pk)
        self.assertEqual(ContentReport.objects.get(request_key='backup-report').details, 'Synthetic review')
        legacy = self.service.create_backup(self.user)
        def downgrade(contents):
            data = json.loads(contents['database.json'])
            del data['content_reports']
            del data['family_branches']
            for row in data['people']: del row['fields']['search_name']
            contents['database.json'] = json.dumps(data).encode()
            manifest = json.loads(contents['manifest.json'])
            manifest['version'] = '6.0'
            manifest['files']['database.json'] = {'size': len(contents['database.json']), 'sha256': hashlib.sha256(contents['database.json']).hexdigest()}
            contents['manifest.json'] = json.dumps(manifest).encode()
        self.tamper(legacy, downgrade)
        self.service.restore_backup(legacy.pk)
        self.assertEqual(Person.objects.get(pk=self.person.pk).search_name, 'before backup')
        self.assertFalse(ContentReport.objects.exists())

    def test_rejected_restore_does_not_change_files_or_database(self):
        backup = self.service.create_backup(self.user)
        target = self.root / 'media/portraits/a.png'
        target.write_bytes(b'current-photo')
        self.tamper(backup, lambda contents: contents.update({'database.json': b'{}'}))
        with self.assertRaises(ValueError): self.service.restore_backup(backup.pk)
        self.assertEqual(target.read_bytes(), b'current-photo')
        self.assertEqual(Person.objects.get(pk=self.person.pk).first_name, 'Before')
        self.assertEqual(HeritageKey.objects.get(pk=self.key.pk).person_id, self.person.pk)

    def test_restore_includes_accounts_keys_files_and_allows_next_insert(self):
        backup = self.service.create_backup(self.user)
        self.person.first_name = 'Changed'; self.person.save()
        self.key.delete(); self.user.first_name = 'Changed'; self.user.save()
        (self.root / 'media/portraits/a.png').write_bytes(b'current-photo')
        self.service.restore_backup(backup.pk)
        self.assertEqual(Person.objects.get(pk=self.person.pk).first_name, 'Before')
        self.assertEqual(HeritageKey.objects.get(key=HeritageKey.verifier('AUDIT-KEY')).person_id, self.person.pk)
        self.user.refresh_from_db(); self.assertEqual(self.user.first_name, '')
        self.assertEqual((self.root / 'media/portraits/a.png').read_bytes(), b'backup-photo')
        new = Person.objects.create(family_tree=self.tree, first_name='Next', last_name='Backup', gender='O')
        self.assertGreater(new.pk, self.person.pk)

    def test_wrong_model_and_missing_sections_rejected(self):
        for alteration in ['model', 'section']:
            backup = self.service.create_backup(self.user)
            def change(contents):
                data = json.loads(contents['database.json'])
                if alteration == 'model': data['people'][0]['model'] = 'users.user'
                else: del data['events']
                contents['database.json'] = json.dumps(data).encode()
                manifest = json.loads(contents['manifest.json'])
                manifest['files']['database.json'] = {'size': len(contents['database.json']), 'sha256': hashlib.sha256(contents['database.json']).hexdigest()}
                contents['manifest.json'] = json.dumps(manifest).encode()
            self.tamper(backup, change)
            with self.assertRaises(ValueError): self.service.restore_backup(backup.pk)
            self.assertTrue(Person.objects.filter(pk=self.person.pk).exists())

    def test_file_write_failure_rolls_back_database_and_files(self):
        second = Person.objects.create(family_tree=self.tree, first_name='Two', last_name='Backup', gender='O', profile_picture='portraits/b.png')
        (self.root / 'media/portraits/b.png').write_bytes(b'backup-second')
        backup = self.service.create_backup(self.user)
        self.person.first_name = 'Current'; self.person.save()
        for name in ['a', 'b']: (self.root / f'media/portraits/{name}.png').write_bytes(b'current')
        import os
        original = os.replace
        calls = []
        def failing(source, target):
            calls.append(target)
            if len(calls) == 2: raise OSError('simulated disk error')
            return original(source, target)
        with patch('backup.services.os.replace', side_effect=failing):
            with self.assertRaises(OSError): self.service.restore_backup(backup.pk)
        self.assertEqual(Person.objects.get(pk=self.person.pk).first_name, 'Current')
        for name in ['a', 'b']: self.assertEqual((self.root / f'media/portraits/{name}.png').read_bytes(), b'current')

    def test_restore_into_empty_domain_rebuilds_memberships_and_links(self):
        from family.models import Relationship, Event
        member = get_user_model().objects.create_user(username='member', email='member@example.test')
        self.tree.members.add(member)
        child = Person.objects.create(family_tree=self.tree,first_name='Child',last_name='Backup',gender='O')
        relation = Relationship.objects.create(person1=self.person,person2=child,relationship_type='PARENT')
        event = Event.objects.create(person=self.person,event_type='BIRTH',date='1970-01-01',description='Recorded')
        backup = self.service.create_backup(self.user)
        FamilyTree.objects.all().delete()
        member.delete()
        (self.root / 'media/portraits/a.png').unlink()
        self.service.restore_backup(backup.pk)
        restored = FamilyTree.objects.get(pk=self.tree.pk)
        self.assertEqual(list(restored.members.values_list('username',flat=True)),['member'])
        self.assertEqual(Relationship.objects.get(pk=relation.pk).person2_id,child.pk)
        self.assertEqual(Event.objects.get(pk=event.pk).person_id,self.person.pk)
        self.assertEqual((self.root / 'media/portraits/a.png').read_bytes(),b'backup-photo')

    def test_path_traversal_archive_is_rejected_without_changes(self):
        backup = self.service.create_backup(self.user)
        self.tamper(backup,lambda contents: contents.update({'media/../../outside.txt':b'unsafe'}))
        with self.assertRaises(ValueError): self.service.restore_backup(backup.pk)
        self.assertFalse((self.root / 'outside.txt').exists())
        self.assertEqual(Person.objects.get(pk=self.person.pk).first_name,'Before')

    def test_s3_download_uses_streaming_body(self):
        import io
        body = io.BytesIO(b'cloud-archive')
        self.service.s3_client = Mock()
        self.service.s3_client.get_object.return_value = {'Body': body}
        self.service.bucket_name = 'test-bucket'
        backup = Backup(file_path='backups/archive.zip')
        with self.service.open_backup(backup) as stream:
            self.assertEqual(stream.read(),b'cloud-archive')
        self.service.s3_client.get_object.assert_called_once_with(Bucket='test-bucket',Key='backups/archive.zip')

    def test_joining_state_and_revisions_survive_full_restore(self):
        from datetime import timedelta
        from django.utils import timezone
        from family.models import TreeMembership, FamilyInvitation, JoinRequest, RecordChange, MutationReceipt
        applicant = get_user_model().objects.create_user(username='restore-applicant', email='restore@example.test')
        self.tree.discovery_enabled = True
        self.tree.save()
        self.tree.members.add(applicant)
        membership = TreeMembership.objects.create(tree=self.tree, user=applicant, person=self.person, role='VIEWER')
        invitation = FamilyInvitation.objects.create(tree=self.tree, anchor=self.person, mode='CHILD',
            secret_digest='f' * 64, expires_at=timezone.now()+timedelta(days=7), created_by=self.user)
        request = JoinRequest.objects.create(tree=self.tree, applicant=applicant, invitation=invitation,
            anchor=self.person, mode='CHILD', person_data={'first_name': 'Child', 'last_name': 'Restore'})
        RecordChange.objects.create(tree=self.tree, actor=self.user, kind='PERSON_EDIT', record_id=self.person.pk, before={'revision': 1}, after={'revision': 2})
        MutationReceipt.objects.create(user=self.user, family_tree=self.tree, key='restore-key', request_hash='a' * 64, response={'saved': True})
        self.person.revision = 2
        self.person.save()
        backup = self.service.create_backup(self.user)
        FamilyTree.objects.all().delete()
        self.service.restore_backup(backup.pk)
        self.assertEqual(TreeMembership.objects.get(pk=membership.pk).role, 'VIEWER')
        self.assertEqual(FamilyInvitation.objects.get(pk=invitation.pk).secret_digest, 'f' * 64)
        self.assertEqual(JoinRequest.objects.get(pk=request.pk).status, 'PENDING')
        self.assertEqual(RecordChange.objects.get(tree_id=self.tree.pk).before, {'revision': 1})
        self.assertEqual(MutationReceipt.objects.get(key='restore-key').response, {'saved': True})
        self.assertEqual(Person.objects.get(pk=self.person.pk).revision, 2)
        self.assertTrue(FamilyTree.objects.get(pk=self.tree.pk).discovery_enabled)

    def test_version_four_archive_preserves_legacy_members_and_defaults(self):
        member = get_user_model().objects.create_user(username='legacy-member', email='legacy@example.test')
        self.tree.members.add(member)
        backup = self.service.create_backup(self.user)
        def downgrade(contents):
            data = json.loads(contents['database.json'])
            for section in ['memberships', 'invitations', 'join_requests', 'record_changes', 'mutation_receipts', 'deletion_requests', 'content_reports', 'family_branches']:
                del data[section]
            for row in data['users']:
                del row['fields']['email_verified']
            for row in data['family_trees']:
                del row['fields']['discovery_enabled']
            for section in ['people', 'relationships']:
                for row in data[section]: del row['fields']['revision']
            contents['database.json'] = json.dumps(data).encode()
            manifest = json.loads(contents['manifest.json'])
            manifest['version'] = '4.0'
            manifest['files']['database.json'] = {'size': len(contents['database.json']), 'sha256': hashlib.sha256(contents['database.json']).hexdigest()}
            contents['manifest.json'] = json.dumps(manifest).encode()
        self.tamper(backup, downgrade)
        self.service.restore_backup(backup.pk)
        self.assertEqual(Person.objects.get(pk=self.person.pk).revision, 1)
        self.tree.refresh_from_db()
        self.assertFalse(self.tree.discovery_enabled)
        from family.permissions import can_access_tree
        self.assertTrue(can_access_tree(member, self.tree, write=True))

    def test_version_five_plaintext_keys_are_upgraded_without_exposing_secret(self):
        backup = self.service.create_backup(self.user)
        def downgrade(contents):
            data = json.loads(contents['database.json'])
            del data['deletion_requests']
            for row in data['users']:
                del row['fields']['email_verified']
            data['heritage_keys'][0]['fields']['key'] = 'AUDIT-KEY'
            contents['database.json'] = json.dumps(data).encode()
            manifest = json.loads(contents['manifest.json'])
            manifest['version'] = '5.0'
            manifest['files']['database.json'] = {'size': len(contents['database.json']), 'sha256': hashlib.sha256(contents['database.json']).hexdigest()}
            contents['manifest.json'] = json.dumps(manifest).encode()
        self.tamper(backup, downgrade)
        self.service.restore_backup(backup.pk)
        self.assertEqual(HeritageKey.objects.get(pk=self.key.pk).key, HeritageKey.verifier('AUDIT-KEY'))
        self.user.refresh_from_db()
        self.assertFalse(self.user.email_verified)

    def test_deletion_review_survives_backup_but_email_codes_do_not(self):
        from users.models import AccountDeletionRequest, EmailAction
        from django.utils import timezone
        request = AccountDeletionRequest.objects.create(user=self.user)
        backup = self.service.create_backup(self.user)
        EmailAction.objects.create(user=self.user, purpose='VERIFY', digest='b' * 64,
            account_stamp='c' * 64, expires_at=timezone.now())
        request.delete()
        self.service.restore_backup(backup.pk)
        self.assertEqual(AccountDeletionRequest.objects.get(user=self.user).status, 'PENDING')
        self.assertEqual(EmailAction.objects.count(), 0)

    def test_selected_branch_consent_survives_restore_and_version_eight_is_supported(self):
        from family.models import FamilyBranchLink
        target = FamilyTree.objects.create(name='Extended', owner=self.user)
        anchor = Person.objects.create(family_tree=target, first_name='Before', last_name='Backup', gender='O')
        hidden = Person.objects.create(family_tree=self.tree, first_name='Hidden', last_name='Relative', gender='O')
        link = FamilyBranchLink.objects.create(source_tree=self.tree, target_tree=target,
            source_root=self.person, attachment=anchor, label='Selected branch', connection='EXISTING',
            status='WITHDRAWN', revision=4, created_by=self.user)
        link.shared_people.add(self.person)
        backup = self.service.create_backup(self.user)
        FamilyTree.objects.all().delete()
        self.service.restore_backup(backup.pk)
        restored = FamilyBranchLink.objects.get(pk=link.pk)
        self.assertEqual(restored.status, 'WITHDRAWN')
        self.assertEqual(restored.revision, 4)
        self.assertEqual(list(restored.shared_people.values_list('pk', flat=True)), [self.person.pk])
        self.assertTrue(Person.objects.filter(pk=hidden.pk).exists())
        legacy = self.service.create_backup(self.user)
        def downgrade(contents):
            data = json.loads(contents['database.json'])
            del data['family_branches']
            contents['database.json'] = json.dumps(data).encode()
            manifest = json.loads(contents['manifest.json'])
            manifest['version'] = '8.0'
            manifest['files']['database.json'] = {'size': len(contents['database.json']), 'sha256': hashlib.sha256(contents['database.json']).hexdigest()}
            contents['manifest.json'] = json.dumps(manifest).encode()
        self.tamper(legacy, downgrade)
        self.service.restore_backup(legacy.pk)
        self.assertFalse(FamilyBranchLink.objects.exists())
        self.assertTrue(Person.objects.filter(pk=self.person.pk).exists())
