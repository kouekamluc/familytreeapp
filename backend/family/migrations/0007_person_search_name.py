import unicodedata
from django.db import migrations, models


def populate(apps, schema_editor):
    Person = apps.get_model('family', 'Person')
    for person in Person.objects.using(schema_editor.connection.alias).iterator(chunk_size=1000):
        value = unicodedata.normalize('NFKD', f'{person.first_name} {person.last_name}').casefold()
        name = ' '.join(''.join(c for c in value if not unicodedata.combining(c)).split())
        Person.objects.using(schema_editor.connection.alias).filter(pk=person.pk).update(search_name=name)


class Migration(migrations.Migration):
    dependencies = [('family', '0006_alter_person_unique_together_and_more')]
    operations = [
        migrations.AddField('person', 'search_name', models.CharField(max_length=610, editable=False, default='', db_index=True)),
        migrations.RunPython(populate, migrations.RunPython.noop),
    ]
