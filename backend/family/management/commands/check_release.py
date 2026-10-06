from urllib.parse import urlparse
from django.conf import settings
from django.core.management.base import BaseCommand, CommandError
from django.db import connection
from django.db.migrations.executor import MigrationExecutor
from family.models import FamilyTree, Person, ContentReport
from users.models import AccountDeletionRequest


def public_https(value):
    url = urlparse(value)
    return bool(url.scheme == 'https' and url.hostname and url.hostname not in ('localhost', '127.0.0.1', '10.0.2.2') and not url.username and not url.password)


class Command(BaseCommand):
    help = 'Read-only release configuration and workflow audit. Does not deploy, email, delete data or certify production readiness.'
    def handle(self, *args, **options):
        failures = []
        checks = {
            'Debug mode disabled': not settings.DEBUG,
            'Production database is PostgreSQL': connection.vendor == 'postgresql',
            'Public HTTPS service URL configured': public_https(settings.PUBLIC_BASE_URL),
            'Support email configured': '@' in settings.SUPPORT_EMAIL and not settings.SUPPORT_EMAIL.endswith(('.test', '@localhost')),
            'Public privacy resource configured': public_https(settings.PRIVACY_POLICY_URL),
            'Reviewed deletion policy version recorded': bool(settings.ACCOUNT_DELETION_POLICY_VERSION),
            'SMTP provider configured': settings.EMAIL_HOST not in ('', 'localhost', '127.0.0.1') and settings.EMAIL_BACKEND.endswith('.smtp.EmailBackend'),
            'Real sender configured': '@' in settings.DEFAULT_FROM_EMAIL and 'localhost' not in settings.DEFAULT_FROM_EMAIL,
            'Private family boundary enabled': not settings.ALLOW_PUBLIC_FAMILY_READS,
        }
        executor = MigrationExecutor(connection)
        checks['Database migrations applied'] = not executor.migration_plan(executor.loader.graph.leaf_nodes())
        for name, passed in checks.items():
            self.stdout.write(f'{"PASS" if passed else "BLOCKED"}: {name}')
            if not passed: failures.append(name)
        if checks['Database migrations applied']:
            self.stdout.write(f'Legacy public flags (currently blocked): {FamilyTree.objects.filter(is_public=True).count()}')
            self.stdout.write(f'People without a family (not discoverable): {Person.objects.filter(family_tree__isnull=True).count()}')
            self.stdout.write(f'Pending deletion reviews: {AccountDeletionRequest.objects.filter(status="PENDING").count()}')
            self.stdout.write(f'Open content reviews: {ContentReport.objects.exclude(status="RESOLVED").count()}')
        self.stdout.write('Separate evidence still required: actual email delivery, reviewed policies, deletion completion, private media hosting, off-device restore, monitoring owner, signed device testing and family pilot.')
        if failures:
            raise CommandError(f'{len(failures)} release configuration checks are blocked. No data was changed.')
