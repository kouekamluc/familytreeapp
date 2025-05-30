from django.db import models
from django.conf import settings
from family.models import Person, Media

class Tag(models.Model):
    """Model for tagging people and media items."""
    name = models.CharField(max_length=50, unique=True)
    description = models.TextField(blank=True)
    color = models.CharField(max_length=7, default='#000000')  # Hex color code
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Many-to-many relationships
    people = models.ManyToManyField(Person, related_name='tags', blank=True)
    media_items = models.ManyToManyField(Media, related_name='tags', blank=True)
    
    class Meta:
        ordering = ['name']
    
    def __str__(self):
        return self.name
