from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.contrib.auth.hashers import check_password

User = get_user_model()

class Command(BaseCommand):
    help = 'Verify user credentials'

    def add_arguments(self, parser):
        parser.add_argument('username', type=str)
        parser.add_argument('password', type=str)

    def handle(self, *args, **options):
        username = options['username']
        password = options['password']

        try:
            user = User.objects.get(username=username)
            self.stdout.write(f"User found: {user.username}")
            self.stdout.write(f"User is active: {user.is_active}")
            self.stdout.write(f"User is staff: {user.is_staff}")
            self.stdout.write(f"User is superuser: {user.is_superuser}")
            
            # Check password
            if check_password(password, user.password):
                self.stdout.write(self.style.SUCCESS("Password is correct"))
            else:
                self.stdout.write(self.style.ERROR("Password is incorrect"))
                
        except User.DoesNotExist:
            self.stdout.write(self.style.ERROR(f"User {username} does not exist")) 