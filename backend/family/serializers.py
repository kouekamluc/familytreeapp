from rest_framework import serializers
from .models import Person, Relationship, Event, Media
from django.contrib.auth import get_user_model

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'email', 'username', 'first_name', 'last_name', 'profile_picture']
        read_only_fields = ['id']

class PersonSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    full_name = serializers.SerializerMethodField()
    
    class Meta:
        model = Person
        fields = [
            'id', 'user', 'first_name', 'last_name', 'full_name', 'gender',
            'date_of_birth', 'date_of_death', 'birth_place', 'current_location',
            'biography', 'is_living', 'profile_picture', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_full_name(self, obj):
        return f"{obj.first_name} {obj.last_name}"

class RelationshipSerializer(serializers.ModelSerializer):
    person1_details = PersonSerializer(source='person1', read_only=True)
    person2_details = PersonSerializer(source='person2', read_only=True)
    
    class Meta:
        model = Relationship
        fields = [
            'id', 'person1', 'person2', 'person1_details', 'person2_details',
            'relationship_type', 'start_date', 'end_date', 'is_current',
            'notes', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

class EventSerializer(serializers.ModelSerializer):
    person_details = PersonSerializer(source='person', read_only=True)
    related_person_details = PersonSerializer(source='related_person', read_only=True)
    
    class Meta:
        model = Event
        fields = [
            'id', 'person', 'person_details', 'event_type', 'date',
            'location', 'description', 'related_person', 'related_person_details',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

class MediaSerializer(serializers.ModelSerializer):
    people_details = PersonSerializer(source='people', many=True, read_only=True)
    uploaded_by_details = UserSerializer(source='uploaded_by', read_only=True)
    
    class Meta:
        model = Media
        fields = [
            'id', 'title', 'media_type', 'file', 'description',
            'date_taken', 'location', 'people', 'people_details',
            'event', 'uploaded_by', 'uploaded_by_details',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at'] 