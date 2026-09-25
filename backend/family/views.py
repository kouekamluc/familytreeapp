from django.shortcuts import render, get_object_or_404
from django.db import models, transaction
from django.contrib.auth import get_user_model
from rest_framework import viewsets, permissions, filters, status, exceptions, serializers
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend

from .models import FamilyTree, Person, Relationship, Event, Media
from .serializers import (
    FamilyTreeSerializer, FamilyTreeDetailSerializer,
    PersonSerializer, RelationshipSerializer,
    EventSerializer, MediaSerializer
)
from .permissions import IsTreeReadable, can_access_tree

User = get_user_model()


def require_tree_editor(user, tree):
    if not can_access_tree(user, tree, write=True):
        raise exceptions.PermissionDenied("You cannot modify this family tree.")


class FamilyTreeViewSet(viewsets.ModelViewSet):
    serializer_class = FamilyTreeSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsTreeReadable]
    
    def get_queryset(self):
        user = self.request.user
        if user and user.is_authenticated and user.is_superuser:
            return FamilyTree.objects.all()
        if user and user.is_authenticated:
            return FamilyTree.objects.filter(
                models.Q(owner=user) | models.Q(members=user) | models.Q(is_public=True)
            ).distinct()
        return FamilyTree.objects.filter(is_public=True).distinct()
    
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return FamilyTreeDetailSerializer
        return FamilyTreeSerializer

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)

    def perform_update(self, serializer):
        tree = self.get_object()
        if tree.owner != self.request.user and not self.request.user.is_superuser:
            raise exceptions.PermissionDenied("Only the tree owner can modify tree settings.")
        serializer.save()

    def perform_destroy(self, instance):
        if instance.owner != self.request.user and not self.request.user.is_superuser:
            raise exceptions.PermissionDenied("Only the tree owner can delete this family tree.")
        instance.delete()
    
    @action(detail=True, methods=['post'])
    def add_member(self, request, pk=None):
        tree = self.get_object()
        if tree.owner != request.user and not request.user.is_superuser:
            return Response(
                {'error': 'Only the tree owner can add members to this tree.'},
                status=status.HTTP_403_FORBIDDEN
            )

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
        if tree.owner != request.user and not request.user.is_superuser:
            return Response(
                {'error': 'Only the tree owner can remove members from this tree.'},
                status=status.HTTP_403_FORBIDDEN
            )

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
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsTreeReadable]
    pagination_class = None
    
    def get_queryset(self):
        user = self.request.user
        if user and user.is_authenticated and user.is_superuser:
            user_trees = FamilyTree.objects.all()
        elif user and user.is_authenticated:
            user_trees = FamilyTree.objects.filter(
                models.Q(owner=user) | models.Q(members=user) | models.Q(is_public=True)
            )
        else:
            user_trees = FamilyTree.objects.filter(is_public=True)

        tree_id = self.request.query_params.get('tree_id') or self.request.query_params.get('family_tree')
        if tree_id:
            return Person.objects.filter(family_tree_id=tree_id, family_tree__in=user_trees)
        return Person.objects.filter(family_tree__in=user_trees)
    
    def perform_create(self, serializer):
        user = self.request.user
        if not user or not user.is_authenticated:
            raise exceptions.PermissionDenied("Authentication required to add people.")

        tree_id = (
            self.request.data.get('family_tree') or
            self.request.data.get('tree_id') or
            self.request.data.get('tree') or
            self.request.data.get('family_tree_id')
        )
        if tree_id:
            tree = get_object_or_404(FamilyTree, id=tree_id)
        else:
            tree = FamilyTree.objects.filter(owner=user).first()
            if not tree:
                tree = FamilyTree.objects.create(name=f"{user.username}'s Family Tree", owner=user)

        # Enforce tree authorization: user must be owner, member, or superuser
        if tree.owner != user and not tree.members.filter(id=user.id).exists() and not user.is_superuser:
            raise exceptions.PermissionDenied("You do not have permission to add people to this family tree.")

        serializer.save(family_tree=tree)

    def perform_update(self, serializer):
        person = self.get_object()
        user = self.request.user
        tree = person.family_tree
        require_tree_editor(user, tree)
        if 'family_tree' in serializer.validated_data and serializer.validated_data['family_tree'] != tree:
            raise serializers.ValidationError({'family_tree': 'Moving a person between trees is not supported.'})
        serializer.save()

    def perform_destroy(self, instance):
        user = self.request.user
        tree = instance.family_tree
        if tree and tree.owner != user and not tree.members.filter(id=user.id).exists() and not user.is_superuser:
            raise exceptions.PermissionDenied("You do not have permission to delete individuals from this family tree.")
        instance.delete()


class RelationshipViewSet(viewsets.ModelViewSet):
    serializer_class = RelationshipSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsTreeReadable]
    pagination_class = None
    
    def get_queryset(self):
        user = self.request.user
        if user and user.is_authenticated and user.is_superuser:
            user_trees = FamilyTree.objects.all()
        elif user and user.is_authenticated:
            user_trees = FamilyTree.objects.filter(
                models.Q(owner=user) | models.Q(members=user) | models.Q(is_public=True)
            )
        else:
            user_trees = FamilyTree.objects.filter(is_public=True)

        tree_id = self.request.query_params.get('tree_id') or self.request.query_params.get('family_tree')
        if tree_id:
            return Relationship.objects.filter(
                models.Q(person1__family_tree_id=tree_id) | models.Q(person2__family_tree_id=tree_id),
                person1__family_tree__in=user_trees,
                person2__family_tree__in=user_trees
            ).distinct()

        return Relationship.objects.filter(
            person1__family_tree__in=user_trees,
            person2__family_tree__in=user_trees
        ).distinct()
    
    def create(self, request, *args, **kwargs):
        person1_id = request.data.get('person1')
        person2_id = request.data.get('person2')
        rel_type = (request.data.get('relationship_type') or '').upper()

        if person1_id and person2_id and rel_type:
            # Check if relationship already exists
            existing = self.get_queryset().filter(
                person1_id=person1_id,
                person2_id=person2_id,
                relationship_type=rel_type
            ).first()
            if not existing and rel_type == 'SPOUSE':
                existing = self.get_queryset().filter(
                    person1_id=person2_id,
                    person2_id=person1_id,
                    relationship_type=rel_type
                ).first()
            if existing:
                require_tree_editor(request.user, existing.person1.family_tree)
                serializer = self.get_serializer(existing)
                return Response(serializer.data, status=status.HTTP_200_OK)

        return super().create(request, *args, **kwargs)

    def perform_create(self, serializer):
        user = self.request.user
        if not user or not user.is_authenticated:
            raise exceptions.PermissionDenied("Authentication required to create relationships.")

        person1_id = self.request.data.get('person1')
        person2_id = self.request.data.get('person2')
        
        person1 = get_object_or_404(Person, id=person1_id)
        person2 = get_object_or_404(Person, id=person2_id)
        
        # Enforce data integrity: prevent cross-tree relationships & automatic tree reassignment
        if person1.family_tree_id != person2.family_tree_id:
            raise serializers.ValidationError({
                "error": "Cross-tree relationships are prohibited. Both individuals must belong to the same family tree."
            })
        
        tree = person1.family_tree
        require_tree_editor(user, tree)

        with transaction.atomic():
            serializer.save()

    def perform_update(self, serializer):
        relationship = self.get_object()
        require_tree_editor(self.request.user, relationship.person1.family_tree)
        person1 = serializer.validated_data.get('person1', relationship.person1)
        person2 = serializer.validated_data.get('person2', relationship.person2)
        if person1.family_tree_id != person2.family_tree_id:
            raise serializers.ValidationError({'people': 'Both people must be in the same tree.'})
        require_tree_editor(self.request.user, person1.family_tree)
        serializer.save()

    def perform_destroy(self, instance):
        user = self.request.user
        tree = instance.person1.family_tree if instance.person1 else None
        if tree and tree.owner != user and not tree.members.filter(id=user.id).exists() and not user.is_superuser:
            raise exceptions.PermissionDenied("You do not have permission to delete relationships from this family tree.")
        instance.delete()


class EventViewSet(viewsets.ModelViewSet):
    serializer_class = EventSerializer
    permission_classes = [permissions.IsAuthenticated, IsTreeReadable]
    
    def get_queryset(self):
        user = self.request.user
        if not user or not user.is_authenticated:
            return Event.objects.none()
        user_trees = (FamilyTree.objects.all() if user.is_superuser else
                      FamilyTree.objects.filter(models.Q(owner=user) | models.Q(members=user)))
        tree_id = self.request.query_params.get('tree_id')
        if tree_id:
            return Event.objects.filter(person__family_tree_id=tree_id, person__family_tree__in=user_trees)
        return Event.objects.filter(person__family_tree__in=user_trees)

    def _check_people(self, person, related_person):
        require_tree_editor(self.request.user, person.family_tree)
        if related_person and related_person.family_tree_id != person.family_tree_id:
            raise serializers.ValidationError({'related_person': 'People must be in the same tree.'})

    def perform_create(self, serializer):
        self._check_people(serializer.validated_data['person'], serializer.validated_data.get('related_person'))
        serializer.save()

    def perform_update(self, serializer):
        event = self.get_object()
        person = serializer.validated_data.get('person', event.person)
        related_person = serializer.validated_data.get('related_person', event.related_person)
        self._check_people(person, related_person)
        serializer.save()


class MediaViewSet(viewsets.ModelViewSet):
    serializer_class = MediaSerializer
    permission_classes = [permissions.IsAuthenticated, IsTreeReadable]
    
    def get_queryset(self):
        user = self.request.user
        if not user or not user.is_authenticated:
            return Media.objects.none()
        tree_id = self.request.query_params.get('tree_id')
        person_id = self.request.query_params.get('person_id')
        media_type = self.request.query_params.get('media_type')
        
        user_trees = (FamilyTree.objects.all() if user.is_superuser else
                      FamilyTree.objects.filter(models.Q(owner=user) | models.Q(members=user)))
        qs = Media.objects.filter(
            models.Q(people__family_tree__in=user_trees) |
            models.Q(event__person__family_tree__in=user_trees) |
            models.Q(uploaded_by=user)
        ).distinct()
        # Old records may contain associations to several trees. Never serialize
        # their other people's details to a user who can see only one tree.
        unauthorized_people = Person.objects.exclude(family_tree__in=user_trees)
        qs = qs.exclude(pk__in=Media.objects.filter(
            people__in=unauthorized_people).values('pk'))
        qs = qs.exclude(pk__in=Media.objects.exclude(event__isnull=True)
                        .exclude(event__person__family_tree__in=user_trees).values('pk'))
        
        if tree_id:
            qs = qs.filter(
                models.Q(people__family_tree_id=tree_id) |
                models.Q(event__person__family_tree_id=tree_id)
            ).filter(
                models.Q(people__family_tree__in=user_trees) |
                models.Q(event__person__family_tree__in=user_trees)
            )
        if person_id:
            qs = qs.filter(people__id=person_id)
        if media_type:
            qs = qs.filter(media_type=media_type.upper())
            
        return qs
    
    def perform_create(self, serializer):
        self._check_associations(serializer.validated_data.get('people', []),
                                 serializer.validated_data.get('event'))
        serializer.save(uploaded_by=self.request.user)

    def perform_update(self, serializer):
        media = self.get_object()
        people = serializer.validated_data.get('people', list(media.people.all()))
        event = serializer.validated_data.get('event', media.event)
        self._check_associations(people, event)
        serializer.save()

    def _check_associations(self, people, event):
        trees = {person.family_tree_id for person in people}
        if event:
            trees.add(event.person.family_tree_id)
        if len(trees) > 1:
            raise serializers.ValidationError({'people': 'All associations must belong to one tree.'})
        for tree_id in trees:
            require_tree_editor(self.request.user, FamilyTree.objects.filter(id=tree_id).first())
