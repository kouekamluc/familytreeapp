from datetime import timedelta
from rest_framework import serializers
from .models import Backup

class BackupSerializer(serializers.ModelSerializer):
    duration = serializers.SerializerMethodField()
    is_completed = serializers.BooleanField(read_only=True)
    is_failed = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = Backup
        fields = [
            'id', 'name', 'backup_type', 'status', 'file_path',
            'file_size', 'created_by', 'created_at', 'completed_at',
            'error_message', 'duration', 'is_completed', 'is_failed'
        ]
        read_only_fields = [
            'file_path', 'file_size', 'created_by', 'created_at',
            'completed_at', 'error_message'
        ]
    
    def get_duration(self, obj) -> timedelta | None:
        return obj.duration 