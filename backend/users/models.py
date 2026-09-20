from django.contrib.auth.models import AbstractUser
from django.db import models
import secrets
import string

class User(AbstractUser):
    """Custom user model for the family tree application."""
    email = models.EmailField(unique=True)
    first_name = models.CharField(max_length=30)
    last_name = models.CharField(max_length=30)
    bio = models.TextField(blank=True)
    profile_picture = models.ImageField(upload_to='profile_pictures/', null=True, blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
    phone_number = models.CharField(max_length=15, blank=True)
    
    # Make email the username field
    USERNAME_FIELD = 'username'
    REQUIRED_FIELDS = ['email', 'first_name', 'last_name']
    
    def __str__(self):
        return self.username

    def get_or_create_primary_heritage_key(self):
        """Returns the primary active heritage key for this user or creates one."""
        key_obj = self.heritage_keys.filter(is_active=True).first()
        if not key_obj:
            new_key = HeritageKey.generate_royal_key_string(prefix="KKEVO-ROYAL")
            key_obj = HeritageKey.objects.create(
                user=self,
                key=new_key,
                name="Primary Royal Lineage Key",
                role="CURATOR" if self.is_staff else "FAMILY_MEMBER"
            )
        return key_obj

    class Meta:
        db_table = 'auth_user'
        swappable = 'AUTH_USER_MODEL'


class HeritageKey(models.Model):
    """Model representing an ancestral Heritage Passkey for rapid, passwordless royal access."""
    ROLE_CHOICES = [
        ('ROYAL_PATRIARCH', 'Royal Patriarch / Elder'),
        ('CURATOR', 'Dynasty Curator'),
        ('FAMILY_MEMBER', 'Lineage Member'),
        ('GUEST_VIEWER', 'Guest Lineage Viewer'),
    ]

    key = models.CharField(
        max_length=64,
        unique=True,
        db_index=True,
        help_text="Sacred Heritage Passkey string, e.g. KKEVO-ROYAL-7A89-B42F"
    )
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='heritage_keys',
        help_text="User associated with this Heritage Key"
    )
    name = models.CharField(max_length=100, default="Sacred Heritage Key")
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='FAMILY_MEMBER')
    family_tree = models.ForeignKey(
        'family.FamilyTree',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='heritage_keys',
        help_text="Family tree this key grants access to"
    )
    person = models.ForeignKey(
        'family.Person',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='heritage_keys',
        help_text="Person in the family tree this key is bound to"
    )
    is_active = models.BooleanField(default=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    last_used_at = models.DateTimeField(null=True, blank=True)
    usage_count = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Heritage Key'
        verbose_name_plural = 'Heritage Keys'

    def __str__(self):
        return f"{self.name} ({self.key}) - {self.user.username}"

    @classmethod
    def generate_royal_key_string(cls, prefix="KKEVO-ROYAL"):
        """Generates a secure, human-readable royal formatted key like KKEVO-ROYAL-XXXX-XXXX."""
        alphabet = string.ascii_uppercase + string.digits.replace('0', '').replace('O', '').replace('I', '').replace('1', '')
        part1 = ''.join(secrets.choice(alphabet) for _ in range(4))
        part2 = ''.join(secrets.choice(alphabet) for _ in range(4))
        candidate = f"{prefix}-{part1}-{part2}"
        # Ensure unique
        while cls.objects.filter(key=candidate).exists():
            part1 = ''.join(secrets.choice(alphabet) for _ in range(4))
            part2 = ''.join(secrets.choice(alphabet) for _ in range(4))
            candidate = f"{prefix}-{part1}-{part2}"
        return candidate

