from django.contrib import admin
from .models import Person, Relationship, Event, Media

@admin.register(Person)
class PersonAdmin(admin.ModelAdmin):
    list_display = ('first_name', 'last_name', 'gender', 'date_of_birth', 'is_living')
    list_filter = ('gender', 'is_living')
    search_fields = ('first_name', 'last_name', 'biography')
    date_hierarchy = 'date_of_birth'

@admin.register(Relationship)
class RelationshipAdmin(admin.ModelAdmin):
    list_display = ('person1', 'person2', 'relationship_type', 'start_date', 'is_current')
    list_filter = ('relationship_type', 'is_current')
    search_fields = ('person1__first_name', 'person1__last_name', 'person2__first_name', 'person2__last_name')
    date_hierarchy = 'start_date'

@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    list_display = ('person', 'event_type', 'date', 'location')
    list_filter = ('event_type',)
    search_fields = ('person__first_name', 'person__last_name', 'description', 'location')
    date_hierarchy = 'date'

@admin.register(Media)
class MediaAdmin(admin.ModelAdmin):
    list_display = ('title', 'media_type', 'date_taken', 'uploaded_by')
    list_filter = ('media_type',)
    search_fields = ('title', 'description', 'location')
    date_hierarchy = 'date_taken'
    filter_horizontal = ('people',)
