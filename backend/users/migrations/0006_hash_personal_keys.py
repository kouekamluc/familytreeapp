from django.db import migrations
import hashlib
import re


def secure_keys(apps, schema_editor):
    Key = apps.get_model('users', 'HeritageKey')
    replacements, seen = [], set()
    for key in Key.objects.all().iterator():
        digest = key.key if re.fullmatch(r'[0-9a-f]{64}', key.key) else hashlib.sha256(key.key.strip().upper().encode()).hexdigest()
        if digest in seen:
            raise ValueError('Duplicate normalized personal keys require operator review before migration.')
        seen.add(digest)
        replacements.append((key.pk, digest))
    for pk, digest in replacements:
        Key.objects.filter(pk=pk).update(key=digest)


class Migration(migrations.Migration):
    dependencies = [('users', '0005_user_email_verified_accountdeletionrequest_and_more')]
    operations = [migrations.RunPython(secure_keys, migrations.RunPython.noop)]
