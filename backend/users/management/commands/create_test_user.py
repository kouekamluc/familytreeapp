from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.contrib.auth.hashers import make_password

User = get_user_model()

class Command(BaseCommand):
    help = 'Create a test user for development'

    def handle(self, *args, **options):
        username = 'testuser'
        password = 'test123'  # Simpler password for testing
        email = 'test@example.com'

        # Check if user exists
        if User.objects.filter(username=username).exists():
            self.stdout.write(f"User {username} already exists")
            return

        # Create user
        user = User.objects.create(
            username=username,
            email=email,
            password=make_password(password),
            is_active=True,
            is_staff=True,
            is_superuser=True
        )

        self.stdout.write(self.style.SUCCESS(f"Successfully created test user: {username}"))
        self.stdout.write(f"Username: {username}")
        self.stdout.write(f"Password: {password}") 