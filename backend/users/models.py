from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    """Custom user model for the family tree application."""
    email = models.EmailField(unique=True)
    bio = models.TextField(blank=True)
    profile_picture = models.ImageField(upload_to='profile_pictures/', null=True, blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
    phone_number = models.CharField(max_length=15, blank=True)
    
    # Make email the username field
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']
    
    def __str__(self):
        return self.email
