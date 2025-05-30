from django.shortcuts import render
from rest_framework import viewsets, permissions, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from .models import Person, Relationship, Event, Media
from .serializers import (
    PersonSerializer, RelationshipSerializer,
    EventSerializer, MediaSerializer
)

# Create your views here.

class PersonViewSet(viewsets.ModelViewSet):
    queryset = Person.objects.all()
    serializer_class = PersonSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['gender', 'is_living']
    search_fields = ['first_name', 'last_name', 'biography']
    ordering_fields = ['first_name', 'last_name', 'date_of_birth']
    
    @action(detail=True, methods=['get'])
    def relationships(self, request, pk=None):
        person = self.get_object()
        relationships = Relationship.objects.filter(person1=person) | Relationship.objects.filter(person2=person)
        serializer = RelationshipSerializer(relationships, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'])
    def events(self, request, pk=None):
        person = self.get_object()
        events = Event.objects.filter(person=person)
        serializer = EventSerializer(events, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'])
    def media(self, request, pk=None):
        person = self.get_object()
        media = Media.objects.filter(people=person)
        serializer = MediaSerializer(media, many=True)
        return Response(serializer.data)

class RelationshipViewSet(viewsets.ModelViewSet):
    queryset = Relationship.objects.all()
    serializer_class = RelationshipSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['relationship_type', 'is_current']
    search_fields = ['notes']

class EventViewSet(viewsets.ModelViewSet):
    queryset = Event.objects.all()
    serializer_class = EventSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['event_type']
    search_fields = ['description', 'location']
    ordering_fields = ['date']

class MediaViewSet(viewsets.ModelViewSet):
    queryset = Media.objects.all()
    serializer_class = MediaSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['media_type']
    search_fields = ['title', 'description', 'location']
    ordering_fields = ['date_taken', 'created_at']
