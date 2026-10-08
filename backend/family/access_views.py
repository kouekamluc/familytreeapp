from django.db import transaction
from django.utils import timezone
from django.contrib.auth import get_user_model
from rest_framework import exceptions, serializers
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.throttling import ScopedRateThrottle
from drf_spectacular.utils import extend_schema
from drf_spectacular.types import OpenApiTypes

from .models import TreeMembership, FamilyInvitation, JoinRequest, RecordChange
from .branch_views import pending_branch_count
from . import joining


def request_data(item, owner=False):
    result = {'id': item.pk, 'family_name': item.tree.name, 'status': item.status,
              'mode': item.mode, 'created_at': item.created_at, 'reviewed_at': item.reviewed_at}
    result.update(message=item.evidence.get('message', ''),
                  owner_response=item.evidence.get('owner_response', ''),
                  purpose=item.evidence.get('purpose', 'JOIN'))
    if item.status == 'APPROVED':
        membership = TreeMembership.objects.filter(tree=item.tree, user=item.applicant).first()
        if membership and item.tree.members.filter(pk=item.applicant_id).exists():
            result.update(tree_id=item.tree_id, person_id=membership.person_id)
    if owner:
        result.update(applicant=item.applicant.username, person=item.person_data,
                      anchor_name=str(item.anchor) if item.anchor else None, evidence=item.evidence)
    return result


@extend_schema(request=OpenApiTypes.OBJECT, responses=OpenApiTypes.OBJECT)
class FamilyAccessView(APIView):
    permission_classes = [IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'family_join'

    def get(self, request):
        tree_id = request.query_params.get('tree_id')
        if not tree_id:
            items = JoinRequest.objects.filter(applicant=request.user).select_related('tree').order_by('-created_at')[:50]
            return Response({'requests': [request_data(item) for item in items],
                'pending_requests': JoinRequest.objects.filter(applicant=request.user, status='PENDING').count() + pending_branch_count(source_tree__owner=request.user),
                'pending_reviews': JoinRequest.objects.filter(tree__owner=request.user, status='PENDING').count() + pending_branch_count(target_tree__owner=request.user)})
        tree = joining.owner_tree(request.user, tree_id)
        memberships = TreeMembership.objects.filter(tree=tree).select_related('user', 'person')
        records = {m.user_id: m for m in memberships}
        members = [{'user_id': u.id, 'name': u.get_full_name() or u.username,
                    'role': records[u.id].role if u.id in records else 'EDITOR',
                    'person_name': str(records[u.id].person) if u.id in records and records[u.id].person else None}
                   for u in tree.members.all() if u.pk != tree.owner_id]
        invitations = [{'id': i.pk, 'anchor_name': str(i.anchor), 'mode': i.mode,
                        'status': 'EXPIRED' if i.status == 'ACTIVE' and i.expires_at <= timezone.now() else i.status,
                        'expires_at': i.expires_at}
                       for i in tree.invitations.select_related('anchor').order_by('-created_at')[:50]]
        return Response({'discovery_enabled': tree.discovery_enabled, 'members': members, 'invitations': invitations,
            'pending_branches': pending_branch_count(target_tree=tree),
            'requests': [request_data(i, owner=True) for i in tree.join_requests.select_related('applicant', 'tree', 'anchor').order_by('-created_at')[:50]],
            'changes': [{'id': c.id, 'kind': c.kind, 'record_id': c.record_id, 'actor': c.actor.username if c.actor else 'Deleted account', 'created_at': c.created_at}
                        for c in RecordChange.objects.filter(tree=tree).select_related('actor').order_by('-created_at')[:30]]})

    def post(self, request):
        if not isinstance(request.data, dict):
            raise serializers.ValidationError('Choose a valid action.')
        payload, action = request.data, request.data.get('action')
        for name, value in payload.items():
            if name.endswith('_id') and value is not None and (type(value) is not int or value < 1):
                raise serializers.ValidationError({name: 'Choose a valid record.'})
        if action == 'invite':
            return Response(joining.invite(request.user, payload), status=201)
        if action == 'redeem':
            return Response(request_data(joining.redeem(request.user, payload)), status=201)
        if action == 'matches':
            return Response({'matches': joining.ancestry_candidates(request.user, payload)})
        if action == 'request_match':
            return Response(request_data(joining.request_match(request.user, payload)), status=201)
        if action == 'review':
            return Response(request_data(joining.review(request.user, payload), owner=True))
        if action == 'cancel':
            item = JoinRequest.objects.filter(pk=payload.get('request_id'), applicant=request.user).first()
            if not item:
                raise exceptions.NotFound()
            with transaction.atomic():
                from .models import FamilyTree
                FamilyTree.objects.select_for_update().get(pk=item.tree_id)
                item = JoinRequest.objects.select_for_update().get(pk=item.pk)
                if item.status == 'PENDING':
                    item.status = 'CANCELLED'
                    item.save(update_fields=['status'])
            return Response(request_data(item))
        with transaction.atomic():
            tree = joining.owner_tree(request.user, payload.get('tree_id'), lock=True)
            if action == 'discovery':
                value = payload.get('enabled')
                if type(value) is not bool:
                    raise serializers.ValidationError('Choose whether to enable family discovery.')
                tree.discovery_enabled = value
                tree.save(update_fields=['discovery_enabled', 'updated_at'])
            elif action == 'reply':
                item = JoinRequest.objects.select_for_update().filter(pk=payload.get('request_id'), tree=tree, status='PENDING').first()
                if not item:
                    raise exceptions.NotFound()
                reply = serializers.CharField(max_length=1000).run_validation(payload.get('message'))
                item.evidence = {**item.evidence, 'owner_response': reply}
                item.save(update_fields=['evidence'])
            elif action == 'revoke':
                invitation = FamilyInvitation.objects.filter(tree=tree, pk=payload.get('invitation_id')).first()
                if not invitation:
                    raise exceptions.NotFound()
                invitation.status = 'REVOKED'
                invitation.save(update_fields=['status'])
            elif action in ('role', 'remove', 'transfer'):
                user = get_user_model().objects.filter(pk=payload.get('user_id'), is_active=True).first()
                if not user or user.pk == tree.owner_id or not tree.members.filter(pk=user.pk).exists():
                    raise serializers.ValidationError('Choose an active family member.')
                if action == 'remove':
                    tree.members.remove(user)
                    TreeMembership.objects.filter(tree=tree, user=user).delete()
                elif action == 'transfer':
                    previous = tree.owner
                    TreeMembership.objects.update_or_create(tree=tree, user=previous, defaults={'role': 'EDITOR'})
                    tree.members.add(previous)
                    tree.owner = user
                    tree.save(update_fields=['owner', 'updated_at'])
                else:
                    role = payload.get('role')
                    if role not in ('VIEWER', 'EDITOR'):
                        raise serializers.ValidationError('Choose viewing or editing access.')
                    TreeMembership.objects.update_or_create(tree=tree, user=user, defaults={'role': role})
            else:
                raise serializers.ValidationError('This action is unavailable.')
        return Response({'status': 'ok'})
