from django.db import transaction
from django.db.models import Q
from rest_framework import exceptions, serializers
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema
from drf_spectacular.types import OpenApiTypes

from .models import FamilyBranchLink, FamilyTree, Person, Relationship
from .names import normalized
from .permissions import readable_trees, can_access_tree
from .joining import record_change


def valid_identity(link):
    if link.source_root.family_tree_id != link.source_tree_id or link.attachment.family_tree_id != link.target_tree_id:
        return False
    if link.connection != 'EXISTING':
        return True
    root, anchor = link.source_root, link.attachment
    return normalized(str(root)) == normalized(str(anchor)) and not (
        root.date_of_birth and anchor.date_of_birth and root.date_of_birth != anchor.date_of_birth)


def current_consent(link):
    return (link.created_by_id == link.source_tree.owner_id and
            can_access_tree(link.source_tree.owner, link.target_tree) and valid_identity(link) and
            link.shared_people.filter(pk=link.source_root_id, family_tree=link.source_tree).exists())


def branch_data(link, management=False):
    people = list(link.shared_people.filter(family_tree=link.source_tree).order_by('id'))
    ids = [person.pk for person in people]
    # Deliberate allowlist: no biographies, account data, locations, media,
    # unselected relatives, private counts or indirect profile expansion.
    profiles = [{field: getattr(person, field) for field in
        ('id', 'first_name', 'last_name', 'gender', 'date_of_birth', 'date_of_death', 'birth_place', 'is_living')}
        for person in people]
    relationships = list(Relationship.objects.filter(person1_id__in=ids, person2_id__in=ids,
        person1__family_tree=link.source_tree, person2__family_tree=link.source_tree).values(
            'id', 'person1', 'person2', 'relationship_type', 'is_current'))
    result = {'id': link.pk, 'label': link.label, 'connection': link.connection,
        'attachment_id': link.attachment_id, 'root_id': link.source_root_id,
        'people': profiles, 'relationships': relationships, 'status': link.status,
        'revision': link.revision, 'active': link.status == 'APPROVED' and current_consent(link)}
    if management:
        result.update(source_tree_id=link.source_tree_id, target_tree_id=link.target_tree_id,
            target_name=link.target_tree.name, attachment_name=str(link.attachment),
            requester=link.created_by.get_full_name() or link.created_by.username if link.created_by else '')
    return result


def pending_branch_count(**filters):
    links = FamilyBranchLink.objects.filter(status='PENDING', **filters).select_related(
        'source_tree__owner', 'target_tree__owner', 'source_root', 'attachment', 'created_by')
    return sum(1 for link in links if current_consent(link))


class BranchInput(serializers.Serializer):
    source_tree_id = serializers.IntegerField(min_value=1)
    target_tree_id = serializers.IntegerField(min_value=1)
    root_id = serializers.IntegerField(min_value=1)
    attachment_id = serializers.IntegerField(min_value=1)
    shared_ids = serializers.ListField(child=serializers.IntegerField(min_value=1), allow_empty=False, max_length=200)
    label = serializers.CharField(max_length=100)
    connection = serializers.ChoiceField(choices=('EXISTING', 'CHILD', 'SIBLING', 'SPOUSE'))
    link_id = serializers.IntegerField(min_value=1, required=False)
    revision = serializers.IntegerField(min_value=1, required=False)


@extend_schema(request=OpenApiTypes.OBJECT, responses=OpenApiTypes.OBJECT)
class FamilyBranchView(APIView):
    permission_classes = [IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'family_join'

    def get(self, request):
        tree_id = serializers.IntegerField(min_value=1).run_validation(request.query_params.get('tree_id'))
        tree = readable_trees(request.user).filter(pk=tree_id).first()
        if not tree:
            raise exceptions.NotFound()
        links = FamilyBranchLink.objects.filter(Q(source_tree=tree) | Q(target_tree=tree)).select_related(
            'source_tree__owner', 'target_tree__owner', 'source_root', 'attachment', 'created_by')
        outgoing, incoming, visible = [], [], []
        for link in links.order_by('-updated_at'):
            if link.source_tree_id == tree.pk and tree.owner_id == request.user.pk:
                outgoing.append(branch_data(link, management=True))
            if link.target_tree_id == tree.pk:
                consent = current_consent(link)
                if tree.owner_id == request.user.pk and consent and link.status in ('PENDING', 'APPROVED'):
                    incoming.append(branch_data(link, management=True))
                if link.status == 'APPROVED' and consent:
                    visible.append(branch_data(link))
        return Response({'outgoing': outgoing, 'incoming': incoming, 'visible': visible})

    def post(self, request):
        if not isinstance(request.data, dict):
            raise serializers.ValidationError('Choose a valid branch action.')
        if request.data.get('action') == 'publish':
            return self.publish(request)
        link_id = serializers.IntegerField(min_value=1).run_validation(request.data.get('link_id'))
        candidate = FamilyBranchLink.objects.filter(pk=link_id).first()
        if not candidate:
            raise exceptions.NotFound()
        with transaction.atomic():
            list(FamilyTree.objects.select_for_update().filter(pk__in=[candidate.source_tree_id, candidate.target_tree_id]).order_by('pk'))
            link = FamilyBranchLink.objects.select_for_update().select_related('source_tree__owner', 'target_tree__owner', 'source_root', 'attachment', 'created_by').get(pk=link_id)
            action = request.data.get('action')
            expected_owner = link.source_tree.owner_id if action == 'withdraw' else link.target_tree.owner_id
            if request.user.pk != expected_owner:
                raise exceptions.PermissionDenied('Only the relevant tree owner can change branch sharing.')
            revision = serializers.IntegerField(min_value=1).run_validation(request.data.get('revision'))
            if revision != link.revision:
                return Response({'detail': 'This branch changed. Refresh before saving.'}, status=409)
            if action == 'withdraw':
                link.status = 'WITHDRAWN'
            elif action == 'review':
                decision = serializers.ChoiceField(choices=('APPROVED', 'REJECTED')).run_validation(request.data.get('decision'))
                if link.status == 'WITHDRAWN':
                    raise serializers.ValidationError('The owner has withdrawn this branch.')
                if decision == 'APPROVED' and not current_consent(link):
                    raise serializers.ValidationError('The branch identity or owner consent has changed. Request a new connection.')
                link.status, link.reviewed_by = decision, request.user
            else:
                raise serializers.ValidationError('Choose a valid branch action.')
            link.revision += 1
            link.save(update_fields=['status', 'reviewed_by', 'revision', 'updated_at'])
            record_change(link.target_tree, request.user, 'BRANCH_' + link.status, link.pk)
            return Response(branch_data(link, management=True))

    def publish(self, request):
        form = BranchInput(data=request.data)
        form.is_valid(raise_exception=True)
        data = form.validated_data
        if data['source_tree_id'] == data['target_tree_id']:
            raise serializers.ValidationError('Choose a different extended family tree.')
        with transaction.atomic():
            trees = {tree.pk: tree for tree in FamilyTree.objects.select_for_update().filter(
                pk__in=[data['source_tree_id'], data['target_tree_id']]).order_by('pk')}
            source, target = trees.get(data['source_tree_id']), trees.get(data['target_tree_id'])
            if not source or source.owner_id != request.user.pk:
                raise exceptions.PermissionDenied('Only the private tree owner can share its profiles.')
            if not target or not can_access_tree(request.user, target):
                raise exceptions.PermissionDenied('Join the extended family before connecting a private branch.')
            root = Person.objects.filter(pk=data['root_id'], family_tree=source).first()
            anchor = Person.objects.filter(pk=data['attachment_id'], family_tree=target).first()
            ids = set(data['shared_ids'])
            people = Person.objects.filter(pk__in=ids, family_tree=source)
            if not root or not anchor or root.pk not in ids or people.count() != len(ids):
                raise serializers.ValidationError('Share the branch root and choose profiles belonging to your private tree.')
            link = FamilyBranchLink.objects.select_for_update().filter(source_tree=source, target_tree=target).first()
            if link and (data.get('link_id') != link.pk or data.get('revision') != link.revision):
                return Response({'detail': 'This branch changed. Refresh before saving.'}, status=409)
            if not link and data.get('link_id'):
                raise exceptions.NotFound()
            link = link or FamilyBranchLink(source_tree=source, target_tree=target)
            link.source_root, link.attachment = root, anchor
            link.label, link.connection, link.created_by = data['label'], data['connection'], request.user
            if not valid_identity(link):
                raise serializers.ValidationError('For the same-person connection, names and known birth dates must agree.')
            link.status = 'APPROVED' if target.owner_id == request.user.pk else 'PENDING'
            link.reviewed_by = request.user if link.status == 'APPROVED' else None
            link.revision += 1 if link.pk else 0
            link.save()
            link.shared_people.set(people)
            record_change(target, request.user, 'BRANCH_REQUEST', link.pk)
            return Response(branch_data(link, management=True), status=201)
