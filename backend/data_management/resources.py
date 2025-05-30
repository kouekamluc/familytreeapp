from import_export import resources
from family.models import Person, Relationship, Event, Media
from tags.models import Tag

class PersonResource(resources.ModelResource):
    class Meta:
        model = Person
        fields = ('id', 'first_name', 'last_name', 'gender', 'date_of_birth', 
                 'date_of_death', 'birth_place', 'current_location', 'biography', 
                 'is_living', 'profile_picture')
        export_order = fields

class RelationshipResource(resources.ModelResource):
    class Meta:
        model = Relationship
        fields = ('id', 'person1', 'person2', 'relationship_type', 'start_date', 
                 'end_date', 'is_current', 'notes')
        export_order = fields

class EventResource(resources.ModelResource):
    class Meta:
        model = Event
        fields = ('id', 'person', 'event_type', 'date', 'location', 'description', 
                 'related_person')
        export_order = fields

class MediaResource(resources.ModelResource):
    class Meta:
        model = Media
        fields = ('id', 'title', 'media_type', 'file', 'description', 'date_taken', 
                 'location', 'people', 'event', 'uploaded_by')
        export_order = fields

class TagResource(resources.ModelResource):
    class Meta:
        model = Tag
        fields = ('id', 'name', 'description', 'color', 'created_by', 'people', 
                 'media_items')
        export_order = fields 