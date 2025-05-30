from django.db import models
from django.conf import settings
import os

class Backup(models.Model):
    """Model for tracking database backups."""
    BACKUP_TYPES = [
        ('AUTO', 'Automatic'),
        ('MANUAL', 'Manual'),
    ]
    
    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('IN_PROGRESS', 'In Progress'),
        ('COMPLETED', 'Completed'),
        ('FAILED', 'Failed'),
    ]
    
    name = models.CharField(max_length=255)
    backup_type = models.CharField(max_length=10, choices=BACKUP_TYPES)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    file_path = models.CharField(max_length=255)
    file_size = models.BigIntegerField(null=True, blank=True)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    error_message = models.TextField(blank=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.name} ({self.get_backup_type_display()})"
    
    @property
    def is_completed(self):
        return self.status == 'COMPLETED'
    
    @property
    def is_failed(self):
        return self.status == 'FAILED'
    
    @property
    def duration(self):
        if self.completed_at and self.created_at:
            return self.completed_at - self.created_at
        return None
