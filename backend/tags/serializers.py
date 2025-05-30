from rest_framework import serializers
from .models import Tag
from family.serializers import PersonSerializer, MediaSerializer

class TagSerializer(serializers.ModelSerializer):
    people_details = PersonSerializer(source='people', many=True, read_only=True)
    media_items_details = MediaSerializer(source='media_items', many=True, read_only=True)
    created_by_username = serializers.CharField(source='created_by.username', read_only=True)
    
    class Meta:
        model = Tag
        fields = [
            'id', 'name', 'description', 'color', 'created_by', 'created_by_username',
            'people', 'people_details', 'media_items', 'media_items_details',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at'] 