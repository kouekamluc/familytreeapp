import hashlib
import json
import os
import shutil
import tempfile
import zipfile
from pathlib import Path, PurePosixPath

import boto3
from django.conf import settings
from django.contrib.auth import get_user_model
from django.core import serializers
from django.core.management.color import no_style
from django.db import connection, transaction
from django.utils import timezone
from users.models import HeritageKey, AccountDeletionRequest, EmailAction
from family.models import FamilyTree, Person, Relationship, Event, Media, TreeMembership, FamilyInvitation, JoinRequest, RecordChange, MutationReceipt, ContentReport
from tags.models import Tag
from .models import Backup


class BackupService:
    VERSION = '8.0'
    MODELS = {'users': get_user_model(), 'family_trees': FamilyTree, 'people': Person,
              'relationships': Relationship, 'events': Event, 'media': Media,
              'tags': Tag, 'heritage_keys': HeritageKey, 'memberships': TreeMembership,
              'invitations': FamilyInvitation, 'join_requests': JoinRequest,
              'record_changes': RecordChange, 'mutation_receipts': MutationReceipt, 'deletion_requests': AccountDeletionRequest, 'content_reports': ContentReport}
    MAX_ARCHIVE_BYTES = 2 * 1024 * 1024 * 1024

    def __init__(self):
        self.backup_dir = str(getattr(settings, 'BACKUP_ROOT', None) or Path(settings.BASE_DIR) / 'backups')
        Path(self.backup_dir).mkdir(parents=True, exist_ok=True)
        self.bucket_name = os.environ.get('AWS_STORAGE_BUCKET_NAME')
        self.s3_client = (boto3.client('s3') if self.bucket_name and
                          os.environ.get('AWS_ACCESS_KEY_ID') and
                          os.environ.get('AWS_SECRET_ACCESS_KEY') else None)

    @staticmethod
    def _digest(content):
        return hashlib.sha256(content).hexdigest()

    @staticmethod
    def _safe_path(name):
        path = PurePosixPath(name)
        if (not name or path.is_absolute() or '..' in path.parts or
                '\\' in name or ':' in name or path.as_posix() != name):
            raise ValueError('Unsafe archive path.')
        return path

    def create_backup(self, user=None, backup_type='MANUAL'):
        backup = Backup.objects.create(name=f"backup_{timezone.now():%Y%m%d_%H%M%S_%f}",
                                       backup_type=backup_type, created_by=user)
        try:
            backup.status = 'IN_PROGRESS'
            backup.save()
            with transaction.atomic():
                if connection.vendor == 'postgresql':
                    with connection.cursor() as cursor:
                        # Also works when invoked inside an existing transaction.
                        # Block writes while collecting a consistent multi-table snapshot.
                        tables = ', '.join(connection.ops.quote_name(model._meta.db_table)
                                           for model in self.MODELS.values())
                        cursor.execute(f'LOCK TABLE {tables} IN SHARE MODE')
                data = {section: self._serialize_model(model) for section, model in self.MODELS.items()}
                contents = {'database.json': json.dumps(data).encode('utf-8')}
                # Bundle referenced uploads only, never unrelated files or application source.
                for model, field in [(get_user_model(), 'profile_picture'), (Person, 'profile_picture'), (Media, 'file')]:
                    for record in model.objects.exclude(**{field: ''}).exclude(**{field: None}):
                        upload = getattr(record, field)
                        name = self._safe_path(upload.name).as_posix()
                        with upload.storage.open(upload.name, 'rb') as stream:
                            contents[f'media/{name}'] = stream.read()
                manifest = {'version': self.VERSION, 'created_at': timezone.now().isoformat(),
                            'files': {name: {'sha256': self._digest(content), 'size': len(content)}
                                      for name, content in contents.items()}}
                archive = Path(self.backup_dir) / f'{backup.name}.zip'
                with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as output:
                    for name, content in contents.items():
                        output.writestr(name, content)
                    output.writestr('manifest.json', json.dumps(manifest))
            backup.file_path = str(archive)
            if self.s3_client:
                backup.file_path = f'backups/{backup.name}.zip'
                self.s3_client.upload_file(str(archive), self.bucket_name, backup.file_path)
            backup.file_size = archive.stat().st_size
            backup.status = 'COMPLETED'
            backup.completed_at = timezone.now()
            backup.save()
            return backup
        except Exception as error:
            backup.status, backup.error_message = 'FAILED', str(error)
            backup.save()
            raise

    def open_backup(self, backup):
        if self.s3_client and backup.file_path.startswith('backups/'):
            return self.s3_client.get_object(Bucket=self.bucket_name, Key=backup.file_path)['Body']
        return open(backup.file_path, 'rb')

    def _read_archive(self, path):
        with zipfile.ZipFile(path) as archive:
            entries = archive.infolist()
            names = [entry.filename for entry in entries]
            if len(names) != len(set(names)) or sum(e.file_size for e in entries) > self.MAX_ARCHIVE_BYTES:
                raise ValueError('Duplicate entries or oversized archive.')
            for name in names:
                self._safe_path(name)
            if 'manifest.json' not in names:
                raise ValueError('Legacy backup requires offline conversion; no changes were made.')
            manifest = json.loads(archive.read('manifest.json'))
            if manifest.get('version') not in ('4.0', '5.0', '6.0', '7.0', self.VERSION) or not isinstance(manifest.get('files'), dict):
                raise ValueError('Unsupported or invalid backup manifest.')
            if set(names) != set(manifest['files']) | {'manifest.json'}:
                raise ValueError('Archive contents do not match manifest.')
            contents = {}
            for name, expected in manifest['files'].items():
                if name != 'database.json' and not name.startswith('media/'):
                    raise ValueError('Unexpected archive entry.')
                content = archive.read(name)
                if expected != {'size': len(content), 'sha256': self._digest(content)}:
                    raise ValueError('Archive checksum mismatch.')
                contents[name] = content
        data = json.loads(contents['database.json'])
        if manifest.get('version') == '4.0':
            expected = set(self.MODELS) - {'memberships', 'invitations', 'join_requests', 'record_changes', 'mutation_receipts', 'deletion_requests', 'content_reports'}
            if not isinstance(data, dict) or set(data) != expected:
                raise ValueError('Missing or unexpected legacy database sections.')
            for record in data['family_trees']:
                record['fields']['discovery_enabled'] = False
            for section in ('people', 'relationships'):
                for record in data[section]:
                    record['fields']['revision'] = 1
            for section in set(self.MODELS) - expected:
                data[section] = []
        if manifest.get('version') in ('4.0', '5.0'):
            data.setdefault('deletion_requests', [])
            for record in data.get('users', []):
                record['fields'].setdefault('email_verified', False)
        if manifest.get('version') != self.VERSION:
            data.setdefault('content_reports', [])
        # Old backup credentials retain validity without returning to plaintext storage.
        import re
        for record in data.get('heritage_keys', []):
            secret = record['fields'].get('key', '')
            if not re.fullmatch(r'[0-9a-f]{64}', secret):
                record['fields']['key'] = HeritageKey.verifier(secret)
        from family.names import normalized
        for record in data.get('people', []):
            fields = record.get('fields', {})
            if manifest.get('version') != self.VERSION or 'search_name' in fields:
                fields['search_name'] = normalized(f"{fields.get('first_name', '')} {fields.get('last_name', '')}")
        self._validate_records(data, contents)
        return data, contents

    def _validate_records(self, data, contents):
        if not isinstance(data, dict) or set(data) != set(self.MODELS):
            raise ValueError('Missing or unexpected database sections.')
        ids = {}
        for section, model in self.MODELS.items():
            if not isinstance(data[section], list):
                raise ValueError('Invalid database section.')
            label = model._meta.label_lower
            ids[label] = set()
            fields = {field.name for field in model._meta.get_fields() if not field.auto_created}
            for record in data[section]:
                if (not isinstance(record, dict) or record.get('model') != label or
                        not isinstance(record.get('pk'), int) or isinstance(record['pk'], bool) or
                        record['pk'] <= 0 or record['pk'] in ids[label] or
                        not isinstance(record.get('fields'), dict) or set(record['fields']) != fields):
                    raise ValueError(f'Invalid or duplicate record in {section}.')
                ids[label].add(record['pk'])
        for section, model in self.MODELS.items():
            for record in data[section]:
                for field in model._meta.fields:
                    value = record['fields'].get(field.name)
                    if field.many_to_one or field.one_to_one:
                        if value is not None:
                            target = field.remote_field.model._meta.label_lower
                            if target in ids and value not in ids[target]:
                                raise ValueError('Missing foreign key reference.')
                    if field.get_internal_type() in ('FileField', 'ImageField') and value:
                        self._safe_path(value)
                        if f'media/{value}' not in contents:
                            raise ValueError('Referenced upload is missing.')
                for field in model._meta.many_to_many:
                    target = field.remote_field.model._meta.label_lower
                    references = set(record['fields'].get(field.name, []))
                    if target in ids:
                        present = ids[target]
                    else:
                        present = set(field.remote_field.model.objects.filter(pk__in=references).values_list('pk', flat=True))
                    if not references <= present:
                        raise ValueError('Missing membership or permission reference.')

    def restore_backup(self, backup_id):
        backup = Backup.objects.get(pk=backup_id)
        try:
            # All archive parsing, checksums and reference validation precede any writes.
            with tempfile.TemporaryDirectory(prefix='restore-', dir=self.backup_dir) as work:
                archive = Path(work) / 'backup.zip'
                with self.open_backup(backup) as source, archive.open('wb') as dest:
                    shutil.copyfileobj(source, dest)
                data, contents = self._read_archive(archive)
                root = Path(settings.MEDIA_ROOT).resolve()
                root.mkdir(parents=True, exist_ok=True)
                previous = []
                try:
                    with transaction.atomic():
                        # Keep existing operator accounts and backup references; restore snapshot accounts in place.
                        EmailAction.objects.all().delete()
                        for section in ['content_reports', 'deletion_requests', 'mutation_receipts', 'record_changes', 'join_requests', 'invitations', 'memberships', 'tags', 'media', 'events', 'relationships', 'heritage_keys', 'people', 'family_trees']:
                            self.MODELS[section].objects.all().delete()
                        for section, model in self.MODELS.items():
                            self._restore_model(model, data[section])
                        for model in (Person, Relationship, Event, TreeMembership):
                            for record in model.objects.all():
                                record.full_clean()
                        for name, content in contents.items():
                            if not name.startswith('media/'):
                                continue
                            target = (root / name[len('media/'):]).resolve()
                            if not target.is_relative_to(root):
                                raise ValueError('Upload destination escapes media directory.')
                            old_path = Path(work) / f'old-{len(previous)}'
                            existed = target.exists()
                            if existed:
                                shutil.copy2(target, old_path)
                            previous.append((target, old_path if existed else None))
                            target.parent.mkdir(parents=True, exist_ok=True)
                            descriptor, staged_name = tempfile.mkstemp(prefix='.restore-', dir=target.parent)
                            os.close(descriptor)
                            staged = Path(staged_name)
                            try:
                                staged.write_bytes(content)
                                os.replace(staged, target)
                            finally:
                                if staged.exists(): staged.unlink()
                        with connection.cursor() as cursor:
                            for sql in connection.ops.sequence_reset_sql(no_style(), list(self.MODELS.values())):
                                cursor.execute(sql)
                except Exception:
                    for target, old_path in reversed(previous):
                        if old_path is None:
                            if target.exists():
                                target.unlink()
                        else:
                            shutil.copy2(old_path, target)
                    raise
            backup.status = 'COMPLETED'
            backup.completed_at = timezone.now()
            backup.error_message = ''
            backup.save()
            return True
        except Exception as error:
            backup.status, backup.error_message = 'FAILED', str(error)
            backup.save()
            raise

    def _serialize_model(self, model):
        return json.loads(serializers.serialize('json', model.objects.all()))

    def _restore_model(self, model, records):
        for obj in serializers.deserialize('json', json.dumps(records)):
            if type(obj.object) is not model:
                raise ValueError('Unexpected backup model.')
            obj.save()
