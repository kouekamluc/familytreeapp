from django.shortcuts import render, get_object_or_404
from rest_framework import viewsets, permissions, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from .models import FamilyTree, Person, Relationship, Event, Media
from .serializers import (
    FamilyTreeSerializer, FamilyTreeDetailSerializer,
    PersonSerializer, RelationshipSerializer,
    EventSerializer, MediaSerializer
)
from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()

# Create your views here.

class FamilyTreeViewSet(viewsets.ModelViewSet):
    serializer_class = FamilyTreeSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    
    def get_queryset(self):
        user = self.request.user
        if user and user.is_authenticated:
            return FamilyTree.objects.filter(
                models.Q(owner=user) | models.Q(members=user) | models.Q(is_public=True)
            ).distinct()
        return FamilyTree.objects.filter(is_public=True).distinct()
    
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return FamilyTreeDetailSerializer
        return FamilyTreeSerializer
    
    @action(detail=True, methods=['post'])
    def add_member(self, request, pk=None):
        tree = self.get_object()
        user_id = request.data.get('user_id')
        
        if not user_id:
            return Response(
                {'error': 'user_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            user = User.objects.get(id=user_id)
            tree.members.add(user)
            return Response({'status': 'member added'})
        except User.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )
    
    @action(detail=True, methods=['post'])
    def remove_member(self, request, pk=None):
        tree = self.get_object()
        user_id = request.data.get('user_id')
        
        if not user_id:
            return Response(
                {'error': 'user_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            user = User.objects.get(id=user_id)
            if user == tree.owner:
                return Response(
                    {'error': 'Cannot remove the owner'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            tree.members.remove(user)
            return Response({'status': 'member removed'})
        except User.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )

class PersonViewSet(viewsets.ModelViewSet):
    serializer_class = PersonSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    pagination_class = None
    
    def get_queryset(self):
        user = self.request.user
        tree_id = self.request.query_params.get('tree_id') or self.request.query_params.get('family_tree')
        if tree_id:
            return Person.objects.filter(family_tree_id=tree_id)
        if user and user.is_authenticated:
            user_trees = FamilyTree.objects.filter(models.Q(owner=user) | models.Q(members=user) | models.Q(is_public=True))
        else:
            user_trees = FamilyTree.objects.filter(is_public=True)
        return Person.objects.filter(family_tree__in=user_trees)
    
    def perform_create(self, serializer):
        user = self.request.user
        tree_id = self.request.data.get('family_tree') or self.request.data.get('tree_id') or self.request.data.get('tree') or self.request.data.get('family_tree_id')
        if tree_id:
            tree = FamilyTree.objects.filter(id=tree_id).first()
            if not tree:
                tree = FamilyTree.objects.filter(owner=user).first() or FamilyTree.objects.first()
        else:
            tree = FamilyTree.objects.filter(owner=user).first() or FamilyTree.objects.first()
            if not tree:
                tree = FamilyTree.objects.create(name=f"{user.username}'s Family Tree", owner=user)
        serializer.save(family_tree=tree)

class RelationshipViewSet(viewsets.ModelViewSet):
    serializer_class = RelationshipSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    pagination_class = None
    
    def get_queryset(self):
        user = self.request.user
        tree_id = self.request.query_params.get('tree_id') or self.request.query_params.get('family_tree')
        if tree_id:
            return Relationship.objects.filter(
                models.Q(person1__family_tree_id=tree_id) |
                models.Q(person2__family_tree_id=tree_id)
            ).distinct()
        if user and user.is_authenticated:
            user_trees = FamilyTree.objects.filter(models.Q(owner=user) | models.Q(members=user) | models.Q(is_public=True))
        else:
            user_trees = FamilyTree.objects.filter(is_public=True)
        return Relationship.objects.filter(
            models.Q(person1__family_tree__in=user_trees) |
            models.Q(person2__family_tree__in=user_trees)
        ).distinct()
    
    def create(self, request, *args, **kwargs):
        person1_id = request.data.get('person1')
        person2_id = request.data.get('person2')
        rel_type = (request.data.get('relationship_type') or '').upper()

        if person1_id and person2_id and rel_type:
            # Check if relationship already exists
            existing = Relationship.objects.filter(
                person1_id=person1_id,
                person2_id=person2_id,
                relationship_type=rel_type
            ).first()
            if not existing and rel_type == 'SPOUSE':
                # Check reverse for spouse
                existing = Relationship.objects.filter(
                    person1_id=person2_id,
                    person2_id=person1_id,
                    relationship_type=rel_type
                ).first()
            if existing:
                serializer = self.get_serializer(existing)
                return Response(serializer.data, status=status.HTTP_200_OK)

        return super().create(request, *args, **kwargs)

    def perform_create(self, serializer):
        person1_id = self.request.data.get('person1')
        person2_id = self.request.data.get('person2')
        
        person1 = get_object_or_404(Person, id=person1_id)
        person2 = get_object_or_404(Person, id=person2_id)
        
        if person1.family_tree != person2.family_tree:
            # Harmonize tree associations so the relationship saves reliably into the DB
            target_tree = person1.family_tree or person2.family_tree
            if not target_tree:
                target_tree = FamilyTree.objects.filter(owner=self.request.user).first() or FamilyTree.objects.first()
            if person1.family_tree != target_tree:
                person1.family_tree = target_tree
                person1.save(update_fields=['family_tree'])
            if person2.family_tree != target_tree:
                person2.family_tree = target_tree
                person2.save(update_fields=['family_tree'])
        
        serializer.save()

class EventViewSet(viewsets.ModelViewSet):
    serializer_class = EventSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        tree_id = self.request.query_params.get('tree_id')
        if tree_id:
            return Event.objects.filter(person__family_tree_id=tree_id)
        user_trees = FamilyTree.objects.filter(models.Q(owner=user) | models.Q(members=user))
        return Event.objects.filter(person__family_tree__in=user_trees)

class MediaViewSet(viewsets.ModelViewSet):
    serializer_class = MediaSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        tree_id = self.request.query_params.get('tree_id')
        person_id = self.request.query_params.get('person_id')
        media_type = self.request.query_params.get('media_type')
        
        user_trees = FamilyTree.objects.filter(models.Q(owner=user) | models.Q(members=user))
        qs = Media.objects.filter(
            models.Q(people__family_tree__in=user_trees) |
            models.Q(uploaded_by=user)
        ).distinct()
        
        if tree_id:
            qs = qs.filter(people__family_tree_id=tree_id)
        if person_id:
            qs = qs.filter(people__id=person_id)
        if media_type:
            qs = qs.filter(media_type=media_type.upper())
            
        return qs
    
    def perform_create(self, serializer):
        serializer.save(uploaded_by=self.request.user)

