import hashlib
import json
from django.core.serializers.json import DjangoJSONEncoder
from django.shortcuts import render, get_object_or_404
from django.db import models, transaction
from django.contrib.auth import get_user_model
from rest_framework import viewsets, permissions, filters, status, exceptions, serializers
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend

from .models import FamilyTree, Person, Relationship, Event, Media, MutationReceipt, TreeMembership
from .serializers import (
    FamilyTreeSerializer, FamilyTreeDetailSerializer, FamilyTreeListSerializer,
    PersonSerializer, PersonGraphSerializer, RelationshipSerializer,
    EventSerializer, MediaSerializer
)
from .permissions import IsTreeReadable, can_access_tree, readable_trees

User = get_user_model()


class StaleRevision(exceptions.APIException):
    status_code = 409
    default_detail = {'code': 'stale_revision', 'detail': 'This record has changed. Review the latest version before saving your changes.'}


def check_revision(request, instance):
    expected = request.data.get('revision')
    if expected is not None:
        try:
            if int(expected) != instance.revision:
                raise StaleRevision()
        except (TypeError, ValueError):
            raise serializers.ValidationError({'revision': 'This record version is invalid.'})


def require_tree_editor(user, tree):
    if not can_access_tree(user, tree, write=True):
        raise exceptions.PermissionDenied("You cannot modify this family tree.")


class CreateReceiptMixin:
    """An interrupted response can be retried without creating another record."""
    def create(self, request, *args, **kwargs):
        key = request.headers.get('Idempotency-Key')
        if not key:
            return super().create(request, *args, **kwargs)
        if len(key) > 80:
            raise serializers.ValidationError('Invalid submission key.')
        if not request.user.is_authenticated:
            raise exceptions.NotAuthenticated()
        digest = hashlib.sha256(json.dumps({'path': request.path, 'payload': request.data}, sort_keys=True, cls=DjangoJSONEncoder).encode()).hexdigest()
        with transaction.atomic():
            get_object_or_404(User.objects.select_for_update(), pk=request.user.pk)
            receipt = MutationReceipt.objects.filter(user=request.user, key=key).first()
            if receipt:
                if receipt.request_hash != digest:
                    return Response({'detail': 'This submission was already used for different data.'}, status=409)
                require_tree_editor(request.user, receipt.family_tree)
                record = self.get_queryset().filter(pk=receipt.response.get('id')).first()
                if record is None:
                    return Response({'detail': 'This saved record was removed. Refresh the family before starting again.'}, status=409)
                return Response(self.get_serializer(record).data, status=201)
            response = super().create(request, *args, **kwargs)
            if response.status_code == 201:
                record = self.get_queryset().get(pk=response.data['id'])
                tree = record if isinstance(record, FamilyTree) else record.family_tree
                MutationReceipt.objects.create(user=request.user, family_tree=tree, key=key, request_hash=digest,
                    response=json.loads(json.dumps(response.data, cls=DjangoJSONEncoder)))
            return response


class FamilyTreeViewSet(CreateReceiptMixin, viewsets.ModelViewSet):
    serializer_class = FamilyTreeSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsTreeReadable]
    
    def get_queryset(self):
        return readable_trees(self.request.user)
    
    def get_serializer_class(self):
        if self.action == 'list':
            return FamilyTreeListSerializer
        if self.action == 'retrieve':
            return FamilyTreeDetailSerializer
        return FamilyTreeSerializer

    def perform_create(self, serializer):
        with transaction.atomic():
            serializer.save(owner=self.request.user)

    def perform_update(self, serializer):
        with transaction.atomic():
            tree = FamilyTree.objects.select_for_update().get(pk=serializer.instance.pk)
            if tree.owner_id != self.request.user.pk and not self.request.user.is_superuser:
                raise exceptions.PermissionDenied("Only the tree owner can modify tree settings.")
            serializer.instance = tree
            serializer.save()

    def perform_destroy(self, instance):
        with transaction.atomic():
            tree = FamilyTree.objects.select_for_update().get(pk=instance.pk)
            if tree.owner_id != self.request.user.pk and not self.request.user.is_superuser:
                raise exceptions.PermissionDenied("Only the tree owner can delete this family tree.")
            tree.delete()

    @action(detail=True, methods=['post'])
    @transaction.atomic
    def add_member(self, request, pk=None):
        tree = FamilyTree.objects.select_for_update().get(pk=self.get_object().pk)
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
            TreeMembership.objects.get_or_create(tree=tree, user=user, defaults={'role': 'EDITOR'})
            return Response({'status': 'member added'})
        except User.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )
    
    @action(detail=True, methods=['post'])
    @transaction.atomic
    def remove_member(self, request, pk=None):
        tree = FamilyTree.objects.select_for_update().get(pk=self.get_object().pk)
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
            TreeMembership.objects.filter(tree=tree, user=user).delete()
            return Response({'status': 'member removed'})
        except User.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )


class PersonViewSet(CreateReceiptMixin, viewsets.ModelViewSet):
    serializer_class = PersonSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsTreeReadable]
    pagination_class = None

    def get_serializer_class(self):
        if self.action == 'list' and self.request.query_params.get('compact') == '1':
            return PersonGraphSerializer
        return PersonSerializer
    
    def get_queryset(self):
        user_trees = readable_trees(self.request.user)

        tree_id = self.request.query_params.get('tree_id') or self.request.query_params.get('family_tree')
        if tree_id:
            return Person.objects.filter(family_tree_id=tree_id, family_tree__in=user_trees).select_related('user')
        return Person.objects.filter(family_tree__in=user_trees).select_related('user')
    
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

        with transaction.atomic():
            tree = FamilyTree.objects.select_for_update().get(pk=tree.pk)
            require_tree_editor(user, tree)
            serializer.save(family_tree=tree)

    @action(detail=True, methods=['post'])
    def create_relative(self, request, pk=None):
        source = self.get_object()
        require_tree_editor(request.user, source.family_tree)
        role = request.data.get('role')
        roles = {'parent', 'father', 'mother', 'child', 'spouse', 'sibling', 'brother', 'sister'}
        if not isinstance(role, str) or role not in roles or not isinstance(request.data.get('person'), dict):
            raise serializers.ValidationError('Provide a supported role and person object.')
        parental_role = role in {'parent', 'father', 'mother', 'child'}
        link_type = request.data.get('relationship_type', 'PARENT')
        if not isinstance(link_type, str) or link_type not in {'PARENT', 'ADOPTED', 'STEP'} or (not parental_role and 'relationship_type' in request.data):
            raise serializers.ValidationError({'relationship_type': 'Choose a parental link only for a parent or child.'})
        data = dict(request.data['person'])
        if 'generation_tier' not in data:
            data['generation_tier'] = (source.generation_tier if source.generation_tier is not None else 1) + (1 if role == 'child' else -1 if role in {'parent', 'father', 'mother'} else 0)
        for field in ('existing_person_id', 'co_parent_id'):
            value = request.data.get(field)
            if value is not None and (type(value) is not int or value < 1):
                raise serializers.ValidationError({field: 'Provide a valid person ID.'})
        data['family_tree'] = source.family_tree_id
        key = request.headers.get('Idempotency-Key')
        if key and len(key) > 80:
            raise serializers.ValidationError('Invalid idempotency key.')
        digest = hashlib.sha256(json.dumps({'source': source.pk, 'payload': request.data}, sort_keys=True).encode()).hexdigest()
        with transaction.atomic():
            locked_tree = FamilyTree.objects.select_for_update().get(pk=source.family_tree_id)
            require_tree_editor(request.user, locked_tree)
            if key:
                receipt = MutationReceipt.objects.filter(user=request.user, key=key).first()
                if receipt:
                    if receipt.request_hash != digest:
                        return Response({'error': 'This request key was already used for different data.'}, status=409)
                    return Response(receipt.response, status=status.HTTP_201_CREATED)
            existing_id = request.data.get('existing_person_id')
            if existing_id is not None:
                person = get_object_or_404(Person, pk=existing_id, family_tree=source.family_tree)
                person_serializer = self.get_serializer(person)
            else:
                person_serializer = self.get_serializer(data=data)
                person_serializer.is_valid(raise_exception=True)
                person = person_serializer.save(family_tree=source.family_tree)
            parent_role = role in {'parent', 'father', 'mother'}
            relation_data = {
                'person1': person.pk if parent_role else source.pk,
                'person2': source.pk if parent_role else person.pk,
                'relationship_type': (link_type if parent_role or role == 'child' else
                                      'SIBLING' if role in {'sibling', 'brother', 'sister'} else 'SPOUSE'),
                'notes': request.data.get('relationship_notes', ''),
            }
            def save_link(values):
                links = Relationship.objects.filter(relationship_type=values['relationship_type'])
                existing = links.filter(person1_id=values['person1'], person2_id=values['person2']).first()
                if not existing and values['relationship_type'] in {'SPOUSE', 'SIBLING'}:
                    existing = links.filter(person1_id=values['person2'], person2_id=values['person1']).first()
                if existing:
                    return RelationshipSerializer(existing, context=self.get_serializer_context())
                result = RelationshipSerializer(data=values, context=self.get_serializer_context())
                result.is_valid(raise_exception=True)
                result.save()
                return result
            relationship = save_link(relation_data)
            additional = []
            co_parent_id = request.data.get('co_parent_id')
            if co_parent_id is not None:
                if role != 'child':
                    raise serializers.ValidationError({'co_parent_id': 'A co-parent applies only when adding a child.'})
                co_parent = get_object_or_404(Person, pk=co_parent_id, family_tree=source.family_tree)
                if co_parent.pk in (source.pk, person.pk):
                    raise serializers.ValidationError({'co_parent_id': 'Select a different co-parent.'})
                additional.append(save_link({'person1': co_parent.pk, 'person2': person.pk, 'relationship_type': link_type}).data)
            response = json.loads(json.dumps({'person': person_serializer.data, 'relationship': relationship.data, 'additional_relationships': additional}, cls=DjangoJSONEncoder))
            if key:
                MutationReceipt.objects.create(user=request.user, family_tree=source.family_tree, key=key, request_hash=digest, response=response)
        return Response(response,
                        status=status.HTTP_201_CREATED)

    def perform_update(self, serializer):
        person = self.get_object()
        user = self.request.user
        tree = person.family_tree
        require_tree_editor(user, tree)
        if 'family_tree' in serializer.validated_data and serializer.validated_data['family_tree'] != tree:
            raise serializers.ValidationError({'family_tree': 'Moving a person between trees is not supported.'})
        with transaction.atomic():
            tree = FamilyTree.objects.select_for_update().get(pk=tree.pk)
            require_tree_editor(user, tree)
            serializer.instance = Person.objects.select_for_update().get(pk=person.pk)
            check_revision(self.request, serializer.instance)
            from .joining import record_change, person_snapshot
            before = person_snapshot(serializer.instance)
            serializer.validate(serializer.validated_data)
            updated = serializer.save(revision=serializer.instance.revision + 1)
            record_change(tree, user, 'PERSON_EDIT', updated.pk, before, person_snapshot(updated))

    def perform_destroy(self, instance):
        with transaction.atomic():
            tree = FamilyTree.objects.select_for_update().get(pk=instance.family_tree_id)
            require_tree_editor(self.request.user, tree)
            instance.delete()


class RelationshipViewSet(viewsets.ModelViewSet):
    serializer_class = RelationshipSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsTreeReadable]
    pagination_class = None
    
    def get_queryset(self):
        user_trees = readable_trees(self.request.user)

        tree_id = self.request.query_params.get('tree_id') or self.request.query_params.get('family_tree')
        if tree_id:
            return Relationship.objects.filter(
                models.Q(person1__family_tree_id=tree_id) | models.Q(person2__family_tree_id=tree_id),
                person1__family_tree__in=user_trees,
                person2__family_tree__in=user_trees
            ).select_related('person1', 'person2').distinct()

        return Relationship.objects.filter(
            person1__family_tree__in=user_trees,
            person2__family_tree__in=user_trees
        ).select_related('person1', 'person2').distinct()
    
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
            if not existing and rel_type in ('SPOUSE', 'SIBLING'):
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
            tree = FamilyTree.objects.select_for_update().get(pk=tree.pk)
            require_tree_editor(user, tree)
            # A competing write may have changed the graph since initial validation.
            serializer.validate(serializer.validated_data)
            serializer.save()

    def perform_update(self, serializer):
        relationship = self.get_object()
        require_tree_editor(self.request.user, relationship.person1.family_tree)
        person1 = serializer.validated_data.get('person1', relationship.person1)
        person2 = serializer.validated_data.get('person2', relationship.person2)
        if person1.family_tree_id != person2.family_tree_id:
            raise serializers.ValidationError({'people': 'Both people must be in the same tree.'})
        require_tree_editor(self.request.user, person1.family_tree)
        with transaction.atomic():
            tree_ids = sorted({relationship.person1.family_tree_id, person1.family_tree_id})
            for locked_tree in FamilyTree.objects.select_for_update().filter(pk__in=tree_ids).order_by('pk'):
                require_tree_editor(self.request.user, locked_tree)
            serializer.instance = Relationship.objects.select_for_update().get(pk=relationship.pk)
            check_revision(self.request, serializer.instance)
            serializer.validate(serializer.validated_data)
            serializer.save(revision=serializer.instance.revision + 1)

    def perform_destroy(self, instance):
        with transaction.atomic():
            tree = FamilyTree.objects.select_for_update().get(pk=instance.person1.family_tree_id)
            require_tree_editor(self.request.user, tree)
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
