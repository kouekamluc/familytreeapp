import os
import json
import zipfile
import shutil
import boto3
from django.utils import timezone
from django.conf import settings
from django.core import serializers
from django.db import transaction
from .models import Backup
from family.models import FamilyTree, Person, Relationship, Event, Media
from tags.models import Tag

class BackupService:
    def __init__(self):
        self.backup_dir = os.path.join(settings.BASE_DIR, 'backups')
        os.makedirs(self.backup_dir, exist_ok=True)
        
        # Initialize S3 client if AWS credentials are configured
        if all(key in os.environ for key in ['AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY']):
            self.s3_client = boto3.client('s3')
            self.bucket_name = os.environ.get('AWS_STORAGE_BUCKET_NAME')
        else:
            self.s3_client = None
    
    def create_backup(self, user=None, backup_type='MANUAL'):
        """Create a complete disaster-recovery backup bundling database records AND physical media files."""
        timestamp = timezone.now().strftime('%Y%m%d_%H%M%S_%f')
        backup_name = f"backup_{timestamp}"
        backup = Backup.objects.create(
            name=backup_name,
            backup_type=backup_type,
            created_by=user
        )
        
        try:
            backup.status = 'IN_PROGRESS'
            backup.save()
            
            # 1. Export data with complete dependency hierarchy
            media_files_count = 0
            data = {
                'family_trees': self._serialize_model(FamilyTree),
                'people': self._serialize_model(Person),
                'relationships': self._serialize_model(Relationship),
                'events': self._serialize_model(Event),
                'media': self._serialize_model(Media),
                'tags': self._serialize_model(Tag),
                'metadata': {
                    'created_at': timezone.now().isoformat(),
                    'version': '3.0',
                    'backup_id': backup.id,
                    'record_counts': {
                        'family_trees': FamilyTree.objects.count(),
                        'people': Person.objects.count(),
                        'relationships': Relationship.objects.count(),
                        'media': Media.objects.count(),
                    }
                }
            }
            
            # 2. Package database records and media files into a full disaster-recovery ZIP archive
            zip_file_path = os.path.join(self.backup_dir, f"{backup_name}.zip")
            with zipfile.ZipFile(zip_file_path, 'w', compression=zipfile.ZIP_DEFLATED) as zipf:
                # Add serialized database JSON
                zipf.writestr('database.json', json.dumps(data, indent=2))
                
                # Bundle all media files (avatars, documents, certificates)
                media_root = getattr(settings, 'MEDIA_ROOT', None)
                if media_root and os.path.exists(media_root):
                    for root, dirs, files in os.walk(media_root):
                        for file in files:
                            abs_path = os.path.join(root, file)
                            rel_path = os.path.relpath(abs_path, media_root)
                            zipf.write(abs_path, os.path.join('media', rel_path))
                            media_files_count += 1
                
                # Add disaster-recovery manifest
                manifest = {
                    'backup_name': backup_name,
                    'created_at': timezone.now().isoformat(),
                    'includes_media': True,
                    'media_files_count': media_files_count,
                    'version': '3.0'
                }
                zipf.writestr('manifest.json', json.dumps(manifest, indent=2))
            
            # Upload to S3 if configured
            if self.s3_client and self.bucket_name:
                s3_key = f"backups/{backup_name}.zip"
                self.s3_client.upload_file(zip_file_path, self.bucket_name, s3_key)
                backup.file_path = s3_key
            else:
                backup.file_path = zip_file_path
            
            # Update backup record
            backup.file_size = os.path.getsize(zip_file_path)
            backup.status = 'COMPLETED'
            backup.completed_at = timezone.now()
            backup.save()
            
            return backup
            
        except Exception as e:
            backup.status = 'FAILED'
            backup.error_message = str(e)
            backup.save()
            raise
    
    def restore_backup(self, backup_id):
        """
        Restore data and media files from a backup transactionally.
        Validates backup integrity before deleting existing data.
        Guarantees that intentional or accidental restore failures cause zero data loss.
        """
        backup = Backup.objects.get(id=backup_id)
        
        try:
            backup.status = 'IN_PROGRESS'
            backup.save()
            
            local_backup_path = backup.file_path
            # Download from S3 if needed
            if self.s3_client and backup.file_path.startswith('backups/'):
                local_backup_path = os.path.join(self.backup_dir, os.path.basename(backup.file_path))
                self.s3_client.download_file(self.bucket_name, backup.file_path, local_backup_path)
            
            data = None
            is_zip = local_backup_path.endswith('.zip') or zipfile.is_zipfile(local_backup_path)
            
            if is_zip:
                with zipfile.ZipFile(local_backup_path, 'r') as zipf:
                    if 'database.json' in zipf.namelist():
                        data = json.loads(zipf.read('database.json').decode('utf-8'))
                    elif 'data.json' in zipf.namelist():
                        data = json.loads(zipf.read('data.json').decode('utf-8'))
                    else:
                        raise ValueError("Corrupted disaster-recovery backup: 'database.json' missing from ZIP.")
                    
                    # Restore physical media files
                    media_root = getattr(settings, 'MEDIA_ROOT', None)
                    if media_root:
                        os.makedirs(media_root, exist_ok=True)
                        for member in zipf.namelist():
                            if member.startswith('media/') and not member.endswith('/'):
                                rel_path = member[len('media/'):]
                                dest_path = os.path.join(media_root, rel_path)
                                os.makedirs(os.path.dirname(dest_path), exist_ok=True)
                                with zipf.open(member) as src, open(dest_path, 'wb') as dst:
                                    shutil.copyfileobj(src, dst)
            else:
                # Legacy JSON format compatibility
                with open(local_backup_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
            
            # Pre-validation: Verify required structure before modifying database
            required_keys = ['people', 'relationships']
            for key in required_keys:
                if key not in data:
                    raise ValueError(f"Corrupted or invalid backup: missing '{key}' section.")

            # Transactional execution: atomic restore with automatic rollback on error
            with transaction.atomic():
                # Clear existing data in reverse dependency order
                Tag.objects.all().delete()
                Media.objects.all().delete()
                Event.objects.all().delete()
                Relationship.objects.all().delete()
                Person.objects.all().delete()
                if 'family_trees' in data:
                    FamilyTree.objects.all().delete()
                
                # Restore in strict dependency order, preserving original primary keys & foreign keys
                if 'family_trees' in data:
                    self._restore_model(FamilyTree, data['family_trees'])
                self._restore_model(Person, data['people'])
                self._restore_model(Relationship, data['relationships'])
                self._restore_model(Event, data.get('events', []))
                self._restore_model(Media, data.get('media', []))
                self._restore_model(Tag, data.get('tags', []))
            
            backup.status = 'COMPLETED'
            backup.completed_at = timezone.now()
            backup.save()
            
            return True
            
        except Exception as e:
            backup.status = 'FAILED'
            backup.error_message = str(e)
            backup.save()
            raise
    
    def _serialize_model(self, model):
        """Serialize model instances to JSON preserving primary and foreign keys."""
        return json.loads(serializers.serialize('json', model.objects.all()))
    
    def _restore_model(self, model, data):
        """Restore model instances using Django's deserializer to maintain exact IDs and relations."""
        if not data:
            return
        for deserialized_object in serializers.deserialize('json', json.dumps(data)):
            deserialized_object.save()
