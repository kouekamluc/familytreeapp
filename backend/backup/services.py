import os
import json
import boto3
from datetime import datetime
from django.conf import settings
from django.core import serializers
from .models import Backup
from family.models import Person, Relationship, Event, Media
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
        """Create a new backup of the database."""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_name = f"backup_{timestamp}"
        backup = Backup.objects.create(
            name=backup_name,
            backup_type=backup_type,
            created_by=user
        )
        
        try:
            backup.status = 'IN_PROGRESS'
            backup.save()
            
            # Export data from each model
            data = {
                'people': self._serialize_model(Person),
                'relationships': self._serialize_model(Relationship),
                'events': self._serialize_model(Event),
                'media': self._serialize_model(Media),
                'tags': self._serialize_model(Tag),
                'metadata': {
                    'created_at': datetime.now().isoformat(),
                    'version': '1.0',
                    'backup_id': backup.id
                }
            }
            
            # Save backup file
            file_path = os.path.join(self.backup_dir, f"{backup_name}.json")
            with open(file_path, 'w') as f:
                json.dump(data, f, indent=2)
            
            # Upload to S3 if configured
            if self.s3_client:
                s3_key = f"backups/{backup_name}.json"
                self.s3_client.upload_file(file_path, self.bucket_name, s3_key)
                backup.file_path = s3_key
            else:
                backup.file_path = file_path
            
            # Update backup record
            backup.file_size = os.path.getsize(file_path)
            backup.status = 'COMPLETED'
            backup.completed_at = datetime.now()
            backup.save()
            
            return backup
            
        except Exception as e:
            backup.status = 'FAILED'
            backup.error_message = str(e)
            backup.save()
            raise
    
    def restore_backup(self, backup_id):
        """Restore data from a backup."""
        backup = Backup.objects.get(id=backup_id)
        
        try:
            backup.status = 'IN_PROGRESS'
            backup.save()
            
            # Read backup file
            if self.s3_client and backup.file_path.startswith('backups/'):
                response = self.s3_client.get_object(
                    Bucket=self.bucket_name,
                    Key=backup.file_path
                )
                data = json.loads(response['Body'].read())
            else:
                with open(backup.file_path, 'r') as f:
                    data = json.load(f)
            
            # Clear existing data
            Tag.objects.all().delete()
            Media.objects.all().delete()
            Event.objects.all().delete()
            Relationship.objects.all().delete()
            Person.objects.all().delete()
            
            # Restore data
            self._restore_model(Person, data['people'])
            self._restore_model(Relationship, data['relationships'])
            self._restore_model(Event, data['events'])
            self._restore_model(Media, data['media'])
            self._restore_model(Tag, data['tags'])
            
            backup.status = 'COMPLETED'
            backup.completed_at = datetime.now()
            backup.save()
            
            return True
            
        except Exception as e:
            backup.status = 'FAILED'
            backup.error_message = str(e)
            backup.save()
            raise
    
    def _serialize_model(self, model):
        """Serialize model instances to JSON."""
        return json.loads(serializers.serialize('json', model.objects.all()))
    
    def _restore_model(self, model, data):
        """Restore model instances from JSON data."""
        for item in data:
            fields = item['fields']
            model.objects.create(**fields) 