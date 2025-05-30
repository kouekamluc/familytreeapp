from django.db import models
from django.conf import settings
from django.core.validators import MinValueValidator, MaxValueValidator

class Person(models.Model):
    """Model representing a person in the family tree."""
    GENDER_CHOICES = [
        ('M', 'Male'),
        ('F', 'Female'),
        ('O', 'Other'),
    ]
    
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, null=True, blank=True)
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    gender = models.CharField(max_length=1, choices=GENDER_CHOICES)
    date_of_birth = models.DateField(null=True, blank=True)
    date_of_death = models.DateField(null=True, blank=True)
    birth_place = models.CharField(max_length=200, blank=True)
    current_location = models.CharField(max_length=200, blank=True)
    biography = models.TextField(blank=True)
    is_living = models.BooleanField(default=True)
    profile_picture = models.ImageField(upload_to='person_pictures/', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['last_name', 'first_name']
    
    def __str__(self):
        return f"{self.first_name} {self.last_name}"

class Relationship(models.Model):
    """Model representing relationships between people."""
    RELATIONSHIP_TYPES = [
        ('PARENT', 'Parent'),
        ('SPOUSE', 'Spouse'),
        ('SIBLING', 'Sibling'),
        ('ADOPTED', 'Adopted'),
        ('STEP', 'Step'),
    ]
    
    person1 = models.ForeignKey(Person, on_delete=models.CASCADE, related_name='relationships_as_person1')
    person2 = models.ForeignKey(Person, on_delete=models.CASCADE, related_name='relationships_as_person2')
    relationship_type = models.CharField(max_length=10, choices=RELATIONSHIP_TYPES)
    start_date = models.DateField(null=True, blank=True)
    end_date = models.DateField(null=True, blank=True)
    is_current = models.BooleanField(default=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['person1', 'person2', 'relationship_type']
    
    def __str__(self):
        return f"{self.person1} - {self.get_relationship_type_display()} - {self.person2}"

class Event(models.Model):
    """Model representing significant events in a person's life."""
    EVENT_TYPES = [
        ('BIRTH', 'Birth'),
        ('DEATH', 'Death'),
        ('MARRIAGE', 'Marriage'),
        ('DIVORCE', 'Divorce'),
        ('ADOPTION', 'Adoption'),
        ('OTHER', 'Other'),
    ]
    
    person = models.ForeignKey(Person, on_delete=models.CASCADE, related_name='events')
    event_type = models.CharField(max_length=10, choices=EVENT_TYPES)
    date = models.DateField()
    location = models.CharField(max_length=200, blank=True)
    description = models.TextField()
    related_person = models.ForeignKey(Person, on_delete=models.SET_NULL, null=True, blank=True, related_name='related_events')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-date']
    
    def __str__(self):
        return f"{self.person} - {self.get_event_type_display()} - {self.date}"

class Media(models.Model):
    """Model representing media items associated with people or events."""
    MEDIA_TYPES = [
        ('PHOTO', 'Photo'),
        ('DOCUMENT', 'Document'),
        ('VIDEO', 'Video'),
        ('AUDIO', 'Audio'),
    ]
    
    title = models.CharField(max_length=200)
    media_type = models.CharField(max_length=10, choices=MEDIA_TYPES)
    file = models.FileField(upload_to='family_media/')
    description = models.TextField(blank=True)
    date_taken = models.DateField(null=True, blank=True)
    location = models.CharField(max_length=200, blank=True)
    people = models.ManyToManyField(Person, related_name='media_items')
    event = models.ForeignKey(Event, on_delete=models.SET_NULL, null=True, blank=True, related_name='media_items')
    uploaded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-date_taken', '-created_at']
    
    def __str__(self):
        return f"{self.title} ({self.get_media_type_display()})"
