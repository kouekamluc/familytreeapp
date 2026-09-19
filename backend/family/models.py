from django.db import models
from django.conf import settings
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils.translation import gettext_lazy as _

class FamilyTree(models.Model):
    """Model representing a family tree."""
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='owned_trees')
    members = models.ManyToManyField(settings.AUTH_USER_MODEL, related_name='shared_trees', blank=True)
    is_public = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.name

class Person(models.Model):
    """Model representing a person in the family tree."""
    GENDER_CHOICES = [
        ('M', 'Male'),
        ('F', 'Female'),
        ('O', 'Other'),
    ]
    
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, null=True, blank=True)
    family_tree = models.ForeignKey(FamilyTree, on_delete=models.CASCADE, related_name='people', null=True, blank=True)
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    gender = models.CharField(max_length=1, choices=GENDER_CHOICES)
    date_of_birth = models.DateField(null=True, blank=True)
    date_of_death = models.DateField(null=True, blank=True)
    birth_place = models.CharField(max_length=200, blank=True)
    current_location = models.CharField(max_length=200, blank=True)
    traditional_name = models.CharField(max_length=200, blank=True, verbose_name=_("Traditional Name / Nom Coutumier"))
    village_of_origin = models.CharField(max_length=200, blank=True, verbose_name=_("Village of Origin / Chefferie"))
    clan_totem = models.CharField(max_length=200, blank=True, verbose_name=_("Clan Totem / Symbole"))
    generation_tier = models.IntegerField(default=1, blank=True, null=True, verbose_name=_("Generation Tier"))
    biography = models.TextField(blank=True)
    is_living = models.BooleanField(default=True)
    profile_picture = models.ImageField(upload_to='person_pictures/', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['last_name', 'first_name']
        unique_together = ['family_tree', 'first_name', 'last_name', 'date_of_birth']
    
    def __str__(self):
        return f"{self.first_name} {self.last_name}"

    def get_parents(self):
        """Get all parents of this person (where this person is child / person2)."""
        return Person.objects.filter(
            relationships_as_person1__person2=self,
            relationships_as_person1__relationship_type='PARENT'
        ).distinct()

    def get_children(self):
        """Get all children of this person (where this person is parent / person1)."""
        return Person.objects.filter(
            relationships_as_person2__person1=self,
            relationships_as_person2__relationship_type='PARENT'
        ).distinct()

    def get_spouses(self):
        """Get all spouses of this person."""
        spouses_as_p2 = Person.objects.filter(
            relationships_as_person2__person1=self,
            relationships_as_person2__relationship_type='SPOUSE'
        )
        spouses_as_p1 = Person.objects.filter(
            relationships_as_person1__person2=self,
            relationships_as_person1__relationship_type='SPOUSE'
        )
        return (spouses_as_p2 | spouses_as_p1).exclude(id=self.id).distinct()

    def get_siblings(self):
        """Get all siblings of this person (people who share at least one parent)."""
        parents = self.get_parents()
        if not parents.exists():
            return Person.objects.none()
        return Person.objects.filter(
            relationships_as_person2__person1__in=parents,
            relationships_as_person2__relationship_type='PARENT'
        ).exclude(id=self.id).distinct()

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
        ordering = ['-is_current', '-start_date']
    
    def __str__(self):
        return f"{self.person1} - {self.get_relationship_type_display()} - {self.person2}"

    def clean(self):
        """Validate relationship data."""
        from django.core.exceptions import ValidationError
        
        # Ensure people are from the same family tree
        if self.person1.family_tree != self.person2.family_tree:
            raise ValidationError(_("Both people must be from the same family tree."))
        
        # Validate relationship types
        if self.relationship_type == 'PARENT':
            if self.person1.date_of_birth and self.person2.date_of_birth:
                if self.person1.date_of_birth > self.person2.date_of_birth:
                    raise ValidationError(_("Parent cannot be younger than child."))
        
        # Validate dates
        if self.start_date and self.end_date:
            if self.start_date > self.end_date:
                raise ValidationError(_("Start date cannot be after end date."))

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

    def clean(self):
        """Validate event data."""
        from django.core.exceptions import ValidationError
        
        # Ensure related person is from the same family tree
        if self.related_person and self.person.family_tree != self.related_person.family_tree:
            raise ValidationError(_("Related person must be from the same family tree."))
        
        # Validate event dates against person's life dates
        if self.event_type == 'BIRTH' and self.person.date_of_birth:
            if self.date != self.person.date_of_birth:
                raise ValidationError(_("Birth event date must match person's birth date."))
        
        if self.event_type == 'DEATH' and self.person.date_of_death:
            if self.date != self.person.date_of_death:
                raise ValidationError(_("Death event date must match person's death date."))

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
