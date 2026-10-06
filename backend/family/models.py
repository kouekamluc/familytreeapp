from django.db import models
from django.conf import settings
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils.translation import gettext_lazy as _
from .names import normalized


class PersonQuerySet(models.QuerySet):
    def bulk_create(self, objs, **kwargs):
        objs = list(objs)
        for person in objs:
            person.search_name = normalized(str(person))
        return super().bulk_create(objs, **kwargs)

    def bulk_update(self, objs, fields, **kwargs):
        objs = list(objs)
        if {'first_name', 'last_name'} & set(fields):
            for person in objs:
                person.search_name = normalized(str(person))
            fields = list(set(fields) | {'search_name'})
        return super().bulk_update(objs, fields, **kwargs)

class FamilyTree(models.Model):
    """Model representing a family tree."""
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name='owned_trees')
    members = models.ManyToManyField(settings.AUTH_USER_MODEL, related_name='shared_trees', blank=True)
    is_public = models.BooleanField(default=False)
    discovery_enabled = models.BooleanField(default=False)
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
    
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    family_tree = models.ForeignKey(FamilyTree, on_delete=models.CASCADE, related_name='people', null=True, blank=True)
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    search_name = models.CharField(max_length=610, editable=False, default='', db_index=True)
    objects = PersonQuerySet.as_manager()
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
    revision = models.PositiveIntegerField(default=1)
    
    class Meta:
        ordering = ['last_name', 'first_name']
    
    def __str__(self):
        return f"{self.first_name} {self.last_name}"

    def save(self, *args, **kwargs):
        self.search_name = normalized(str(self))
        fields = kwargs.get('update_fields')
        if fields is not None and {'first_name', 'last_name'} & set(fields):
            kwargs['update_fields'] = set(fields) | {'search_name'}
        return super().save(*args, **kwargs)

    def clean(self):
        from django.core.exceptions import ValidationError
        if self.date_of_birth and self.date_of_death and self.date_of_death < self.date_of_birth:
            raise ValidationError({'date_of_death': 'Death cannot be before birth.'})
        if self.is_living and self.date_of_death:
            raise ValidationError({'is_living': 'A living person cannot have a death date.'})
        if self.pk:
            for link in Relationship.objects.filter(
                    models.Q(person1_id=self.pk) | models.Q(person2_id=self.pk), relationship_type='PARENT'):
                parent = self if link.person1_id == self.pk else link.person1
                child = self if link.person2_id == self.pk else link.person2
                if parent.date_of_birth and child.date_of_birth and parent.date_of_birth > child.date_of_birth:
                    raise ValidationError({'date_of_birth': 'Parent cannot be younger than child.'})

    def get_parents(self):
        """Get all parents of this person (where this person is child / person2)."""
        return Person.objects.filter(
            relationships_as_person1__person2=self,
            relationships_as_person1__relationship_type__in=('PARENT', 'ADOPTED', 'STEP')
        ).distinct()

    def get_children(self):
        """Get all children of this person (where this person is parent / person1)."""
        return Person.objects.filter(
            relationships_as_person2__person1=self,
            relationships_as_person2__relationship_type__in=('PARENT', 'ADOPTED', 'STEP')
        ).distinct()

    def get_spouses(self):
        """Get all spouses of this person."""
        spouses_as_p2 = Person.objects.filter(
            relationships_as_person2__person1=self,
            relationships_as_person2__relationship_type='SPOUSE',
            relationships_as_person2__is_current=True,
        )
        spouses_as_p1 = Person.objects.filter(
            relationships_as_person1__person2=self,
            relationships_as_person1__relationship_type='SPOUSE',
            relationships_as_person1__is_current=True,
        )
        return (spouses_as_p2 | spouses_as_p1).exclude(id=self.id).distinct()

    def get_siblings(self):
        """Get all siblings of this person (people who share at least one parent)."""
        parents = self.get_parents()
        return Person.objects.filter(
            models.Q(relationships_as_person2__person1__in=parents,
                     relationships_as_person2__relationship_type__in=('PARENT', 'ADOPTED', 'STEP')) |
            models.Q(relationships_as_person1__person2=self,
                     relationships_as_person1__relationship_type='SIBLING') |
            models.Q(relationships_as_person2__person1=self,
                     relationships_as_person2__relationship_type='SIBLING')
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
    revision = models.PositiveIntegerField(default=1)
    
    class Meta:
        unique_together = ['person1', 'person2', 'relationship_type']
        ordering = ['-is_current', '-start_date']
    
    def __str__(self):
        return f"{self.person1} - {self.get_relationship_type_display()} - {self.person2}"

    def clean(self):
        """Validate relationship data."""
        from django.core.exceptions import ValidationError

        if not self.person1_id or not self.person2_id:
            return
        if self.person1_id == self.person2_id:
            raise ValidationError('A person cannot be related to themselves.')
        
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

        others = Relationship.objects.exclude(pk=self.pk)
        if self.relationship_type in ('SPOUSE', 'SIBLING') and others.filter(
                models.Q(person1_id=self.person1_id, person2_id=self.person2_id) |
                models.Q(person1_id=self.person2_id, person2_id=self.person1_id),
                relationship_type=self.relationship_type).exists():
            raise ValidationError('This symmetric relationship already exists.')
        if self.relationship_type in ('PARENT', 'ADOPTED', 'STEP'):
            edges = others.filter(person1__family_tree_id=self.person1.family_tree_id,
                                  relationship_type__in=('PARENT', 'ADOPTED', 'STEP'))
            children = {}
            for parent, child in edges.values_list('person1_id', 'person2_id'):
                children.setdefault(parent, set()).add(child)
            pending, seen = [self.person2_id], set()
            while pending:
                current = pending.pop()
                if current == self.person1_id:
                    raise ValidationError('This relationship creates an ancestry cycle.')
                if current not in seen:
                    seen.add(current)
                    pending.extend(children.get(current, ()))

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


class MutationReceipt(models.Model):
    """Deduplicates retried compound writes after interrupted responses."""
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    family_tree = models.ForeignKey(FamilyTree, on_delete=models.CASCADE)
    key = models.CharField(max_length=80)
    request_hash = models.CharField(max_length=64)
    response = models.JSONField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=['user', 'key'], name='unique_family_mutation_key')]


class TreeMembership(models.Model):
    tree = models.ForeignKey(FamilyTree, on_delete=models.CASCADE, related_name='access_memberships')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    role = models.CharField(max_length=6, choices=[('VIEWER', 'Viewer'), ('EDITOR', 'Editor')], default='VIEWER')
    person = models.OneToOneField(Person, null=True, blank=True, on_delete=models.SET_NULL, related_name='account_membership')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=['tree', 'user'], name='unique_tree_account_membership')]

    def clean(self):
        from django.core.exceptions import ValidationError
        if self.person_id and self.person.family_tree_id != self.tree_id:
            raise ValidationError('The associated person must belong to this tree.')


class FamilyInvitation(models.Model):
    tree = models.ForeignKey(FamilyTree, on_delete=models.CASCADE, related_name='invitations')
    anchor = models.ForeignKey(Person, on_delete=models.CASCADE, related_name='family_invitations')
    through_parent = models.ForeignKey(Person, on_delete=models.SET_NULL, null=True, blank=True, related_name='+')
    mode = models.CharField(max_length=10, choices=[('EXISTING', 'Existing profile'), ('CHILD', 'Child'), ('GRANDCHILD', 'Grandchild')])
    secret_digest = models.CharField(max_length=64, unique=True)
    status = models.CharField(max_length=10, default='ACTIVE', choices=[('ACTIVE', 'Active'), ('REDEEMED', 'Redeemed'), ('REVOKED', 'Revoked')])
    expires_at = models.DateTimeField()
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name='+')
    created_at = models.DateTimeField(auto_now_add=True)


class JoinRequest(models.Model):
    tree = models.ForeignKey(FamilyTree, on_delete=models.CASCADE, related_name='join_requests')
    applicant = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='family_join_requests')
    invitation = models.OneToOneField(FamilyInvitation, on_delete=models.SET_NULL, null=True, blank=True)
    anchor = models.ForeignKey(Person, on_delete=models.SET_NULL, null=True, related_name='+')
    mode = models.CharField(max_length=10)
    person_data = models.JSONField(default=dict)
    evidence = models.JSONField(default=dict)
    status = models.CharField(max_length=10, default='PENDING', choices=[('PENDING', 'Pending'), ('APPROVED', 'Approved'), ('REJECTED', 'Rejected'), ('CANCELLED', 'Cancelled')])
    reviewed_by = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name='+')
    created_at = models.DateTimeField(auto_now_add=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)


class RecordChange(models.Model):
    tree = models.ForeignKey(FamilyTree, on_delete=models.CASCADE, related_name='record_changes')
    actor = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True)
    kind = models.CharField(max_length=20)
    record_id = models.PositiveBigIntegerField()
    before = models.JSONField(default=dict)
    after = models.JSONField(default=dict)
    created_at = models.DateTimeField(auto_now_add=True)


class ContentReport(models.Model):
    reporter = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name='content_reports')
    tree = models.ForeignKey(FamilyTree, null=True, on_delete=models.SET_NULL)
    person = models.ForeignKey(Person, null=True, on_delete=models.SET_NULL)
    reason = models.CharField(max_length=16, choices=[('PRIVACY', 'Privacy'), ('INCORRECT', 'Incorrect information'), ('INAPPROPRIATE', 'Inappropriate content'), ('OTHER', 'Other')])
    details = models.TextField(max_length=2000)
    status = models.CharField(max_length=12, default='OPEN', choices=[('OPEN', 'Received'), ('IN_REVIEW', 'Under review'), ('RESOLVED', 'Resolved')])
    response = models.TextField(blank=True, max_length=2000)
    request_key = models.CharField(max_length=80)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    class Meta:
        constraints = [models.UniqueConstraint(fields=['reporter', 'request_key'], name='unique_report_request')]
    def clean(self):
        from django.core.exceptions import ValidationError
        if self.status == 'RESOLVED' and not self.response.strip():
            raise ValidationError({'response': 'Explain the resolution to the person who reported the issue.'})
