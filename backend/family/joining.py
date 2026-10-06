"""Explicit, reviewed family joining; personal login keys never grant membership."""
import hashlib
import secrets
from .names import normalized
from datetime import timedelta

from django.core import signing
from django.db import transaction
from django.db.models import Q
from django.utils import timezone
from rest_framework import exceptions, serializers

from .models import FamilyTree, Person, Relationship, TreeMembership, FamilyInvitation, JoinRequest, RecordChange
from .serializers import PersonSerializer, RelationshipSerializer


def owner_tree(user, tree_id, lock=False):
    try:
        tree_id = int(tree_id)
    except (TypeError, ValueError):
        raise serializers.ValidationError('Choose a valid family.')
    query = FamilyTree.objects.select_for_update() if lock else FamilyTree.objects
    tree = query.filter(pk=tree_id).first()
    if not tree or (tree.owner_id != user.id and not user.is_superuser):
        raise exceptions.PermissionDenied('Only the family owner can manage access.')
    return tree


def digest_code(code):
    return hashlib.sha256(str(code).replace('-', '').replace(' ', '').upper().encode()).hexdigest()


def person_snapshot(person):
    return {f.name: getattr(person, f.attname) for f in Person._meta.fields
            if f.name not in ('created_at', 'updated_at', 'profile_picture', 'user', 'id', 'family_tree')}


def record_change(tree, actor, kind, record_id, before=None, after=None):
    import json
    from django.core.serializers.json import DjangoJSONEncoder
    RecordChange.objects.create(tree=tree, actor=actor, kind=kind, record_id=record_id,
        before=json.loads(json.dumps(before or {}, cls=DjangoJSONEncoder)),
        after=json.loads(json.dumps(after or {}, cls=DjangoJSONEncoder)))


def valid_person_data(data, user):
    allowed = ('first_name', 'last_name', 'gender', 'date_of_birth', 'birth_place')
    if not isinstance(data, dict):
        raise serializers.ValidationError('Enter a valid personal profile.')
    data = {k: v for k, v in data.items() if k in allowed}
    data.setdefault('first_name', user.first_name)
    data.setdefault('last_name', user.last_name)
    data.setdefault('gender', 'O')
    form = PersonSerializer(data=data)
    form.is_valid(raise_exception=True)
    return dict(form.validated_data)


def invite(user, payload):
    with transaction.atomic():
        tree = owner_tree(user, payload.get('tree_id'), lock=True)
        anchor = Person.objects.filter(pk=payload.get('anchor_id'), family_tree=tree).first()
        mode = payload.get('mode')
        if not anchor or mode not in ('EXISTING', 'CHILD', 'GRANDCHILD'):
            raise serializers.ValidationError('Choose a valid profile and connection in this family.')
        parent = None
        if mode == 'EXISTING' and (anchor.user_id or TreeMembership.objects.filter(person=anchor).exists()):
            raise serializers.ValidationError('This profile is already connected to an account.')
        if mode == 'GRANDCHILD':
            parent = Person.objects.filter(pk=payload.get('through_parent_id'), family_tree=tree).first()
            if not parent or not Relationship.objects.filter(person1=anchor, person2=parent,
                    relationship_type__in=('PARENT', 'ADOPTED', 'STEP')).exists():
                raise serializers.ValidationError('Choose the recorded parent who is a child of this grandparent.')
        code = secrets.token_hex(12).upper()
        invitation = FamilyInvitation.objects.create(tree=tree, anchor=anchor, through_parent=parent,
            mode=mode, secret_digest=digest_code(code), created_by=user,
            expires_at=timezone.now() + timedelta(days=7))
        return {'id': invitation.id, 'code': '-'.join(code[i:i+4] for i in range(0, len(code), 4)),
                'expires_at': invitation.expires_at, 'message': 'Code à usage unique. Le profil sera confirmé par le propriétaire.'}


def redeem(user, payload):
    from django.core.serializers.json import DjangoJSONEncoder
    import json
    secret = digest_code(payload.get('code', ''))
    # Tree before invitation is the same lock order used by owner review/revoke.
    candidate = FamilyInvitation.objects.filter(secret_digest=secret).first()
    if not candidate:
        raise serializers.ValidationError('This invitation code is invalid, expired or revoked.')
    with transaction.atomic():
        tree = FamilyTree.objects.select_for_update().filter(pk=candidate.tree_id).first()
        invitation = FamilyInvitation.objects.select_for_update().filter(pk=candidate.pk).first()
        if not tree or not invitation:
            raise serializers.ValidationError('This invitation code is invalid, expired or revoked.')
        existing = JoinRequest.objects.filter(invitation=invitation).first()
        if existing and existing.applicant_id == user.id:
            return existing
        if invitation.status != 'ACTIVE' or invitation.expires_at <= timezone.now():
            raise serializers.ValidationError('This invitation code is invalid, expired or revoked.')
        if tree.owner_id == user.id or tree.members.filter(pk=user.pk).exists():
            raise serializers.ValidationError('Your account already has access to this family.')
        data = valid_person_data(payload.get('person', {}), user)
        request = JoinRequest.objects.create(tree=tree, applicant=user, invitation=invitation,
            anchor=invitation.through_parent if invitation.mode == 'GRANDCHILD' else invitation.anchor,
            mode='EXISTING' if invitation.mode == 'EXISTING' else 'CHILD',
            person_data=json.loads(json.dumps(data, cls=DjangoJSONEncoder)))
        invitation.status = 'REDEEMED'
        invitation.save(update_fields=['status'])
        return request


def review(user, payload):
    with transaction.atomic():
        tree = owner_tree(user, payload.get('tree_id'), lock=True)
        request = JoinRequest.objects.select_for_update().filter(pk=payload.get('request_id'), tree=tree).first()
        if not request:
            raise exceptions.NotFound()
        if request.status != 'PENDING':
            return request
        decision = payload.get('decision')
        if decision not in ('APPROVED', 'REJECTED'):
            raise serializers.ValidationError('Choose approve or decline.')
        if decision == 'APPROVED':
            if not request.applicant.is_active or tree.members.filter(pk=request.applicant_id).exists():
                raise serializers.ValidationError('This account is inactive or already a family member.')
            anchor = request.anchor
            if not anchor or anchor.family_tree_id != tree.id:
                raise serializers.ValidationError('The reference profile has changed. Decline this request and create a new invitation.')
            if request.invitation and (request.invitation.status == 'REVOKED' or request.invitation.expires_at <= timezone.now()):
                raise serializers.ValidationError('This invitation has expired or been revoked.')
            if request.invitation and request.invitation.mode == 'GRANDCHILD' and not Relationship.objects.filter(
                    person1=request.invitation.anchor, person2=anchor, relationship_type__in=('PARENT', 'ADOPTED', 'STEP')).exists():
                raise serializers.ValidationError('The grandparent and parent connection has changed. Create a new invitation.')
            if request.evidence and not tree.discovery_enabled:
                raise serializers.ValidationError('Family discovery has been disabled. Use an invitation.')
            if request.evidence:
                parent = validate_match_path(tree, request.evidence['path_parent_id'],
                    request.evidence['path_grandparent_id'], request.evidence['path_type'], request.evidence)
                if request.mode == 'EXISTING':
                    if not Relationship.objects.filter(person1=parent, person2=anchor,
                            relationship_type__in=('PARENT', 'ADOPTED', 'STEP')).exists():
                        raise serializers.ValidationError('The profile has moved to another family. Search again.')
                    if normalized(str(anchor)) != normalized(f"{request.person_data['first_name']} {request.person_data['last_name']}"):
                        raise serializers.ValidationError('The personal profile has changed. Use an invitation for the correct profile.')
                    birth = request.person_data.get('date_of_birth')
                    if birth and anchor.date_of_birth and str(birth) != str(anchor.date_of_birth):
                        raise serializers.ValidationError('The profile birth date has changed. Use an invitation for the correct profile.')
            if request.mode == 'EXISTING':
                person = anchor
                if person.user_id and person.user_id != request.applicant_id:
                    raise serializers.ValidationError('This profile is connected to another account.')
                if TreeMembership.objects.filter(person=person).exists():
                    raise serializers.ValidationError('This profile has already been confirmed for another account.')
            else:
                form = PersonSerializer(data={**request.person_data, 'generation_tier': (anchor.generation_tier or 1) + 1})
                form.is_valid(raise_exception=True)
                person = form.save(family_tree=tree)
                link = RelationshipSerializer(data={'person1': anchor.id, 'person2': person.id, 'relationship_type': 'PARENT'})
                link.is_valid(raise_exception=True)
                link.save()
            TreeMembership.objects.create(tree=tree, user=request.applicant, person=person, role='VIEWER')
            tree.members.add(request.applicant)
            record_change(tree, user, 'JOIN_APPROVED', person.id, after={'applicant_id': request.applicant_id, 'request_id': request.id})
        request.status, request.reviewed_by, request.reviewed_at = decision, user, timezone.now()
        request.save(update_fields=['status', 'reviewed_by', 'reviewed_at'])
        return request



class AncestryInput(serializers.Serializer):
    parent_name = serializers.CharField(max_length=200)
    grandparent_name = serializers.CharField(max_length=200)
    parent_birth_date = serializers.DateField(required=False, allow_null=True)
    parent_birth_place = serializers.CharField(max_length=200, required=False, allow_blank=True)


def validate_match_path(tree, parent_id, grandparent_id, link_type, facts):
    parent = Person.objects.filter(pk=parent_id, family_tree=tree).first()
    gp = Person.objects.filter(pk=grandparent_id, family_tree=tree).first()
    if (not parent or not gp or not Relationship.objects.filter(
            person1=gp, person2=parent, relationship_type=link_type).exists()):
        raise serializers.ValidationError('The family connection has changed. Search again.')
    if (normalized(str(parent)) != normalized(facts['parent_name']) or
            normalized(str(gp)) != normalized(facts['grandparent_name'])):
        raise serializers.ValidationError('The profiles have changed. Search again.')
    birth = facts.get('parent_birth_date')
    place = normalized(facts.get('parent_birth_place', ''))
    if ((birth and parent.date_of_birth and str(parent.date_of_birth) != str(birth)) or
            (place and parent.birth_place and place != normalized(parent.birth_place))):
        raise serializers.ValidationError('The parent details have changed. Search again.')
    return parent


def ancestry_candidates(user, payload):
    from django.core.serializers.json import DjangoJSONEncoder
    import json
    form = AncestryInput(data=payload)
    form.is_valid(raise_exception=True)
    facts = form.validated_data
    parent_name, grandparent_name = normalized(facts['parent_name']), normalized(facts['grandparent_name'])
    if len(parent_name) < 3 or len(grandparent_name) < 3:
        raise serializers.ValidationError('Enter the full names of the parent and grandparent.')
    links = Relationship.objects.filter(person1__family_tree__discovery_enabled=True,
        person2__family_tree__discovery_enabled=True,
        person1__search_name=grandparent_name, person2__search_name=parent_name,
        relationship_type__in=('PARENT', 'ADOPTED', 'STEP'))
    links = links.exclude(Q(person1__family_tree__owner=user) | Q(person1__family_tree__members=user))
    candidates, seen = [], set()
    for link in links.select_related('person1', 'person2', 'person2__family_tree').order_by('id').iterator(chunk_size=200):
        gp, parent = link.person1, link.person2
        if gp.family_tree_id != parent.family_tree_id or normalized(str(gp)) != grandparent_name or normalized(str(parent)) != parent_name:
            continue
        birth = facts.get('parent_birth_date')
        place = normalized(facts.get('parent_birth_place', ''))
        if birth and parent.date_of_birth and birth != parent.date_of_birth:
            continue
        if place and parent.birth_place and place != normalized(parent.birth_place):
            continue
        if parent.pk in seen:
            continue
        seen.add(parent.pk)
        evidence = json.loads(json.dumps(facts, cls=DjangoJSONEncoder))
        token = signing.dumps({'user': user.pk, 'tree': parent.family_tree_id, 'parent': parent.pk,
                              'grandparent': gp.pk, 'type': link.relationship_type, 'evidence': evidence}, salt='family-match-v1')
        candidates.append({'candidate': token, 'family_name': parent.family_tree.name,
            'reason': 'A recorded parent and grandparent connection matches your details. Family confirmation is required.',
            'relationship_type': link.relationship_type})
        if len(candidates) == 10:
            break
    return candidates


def request_match(user, payload):
    import json
    from django.core.serializers.json import DjangoJSONEncoder
    try:
        candidate = signing.loads(payload.get('candidate', ''), salt='family-match-v1', max_age=900)
    except (signing.BadSignature, TypeError):
        raise serializers.ValidationError('This suggestion has expired. Search again.')
    if candidate.get('user') != user.pk:
        raise exceptions.PermissionDenied()
    with transaction.atomic():
        tree = FamilyTree.objects.select_for_update().filter(pk=candidate['tree'], discovery_enabled=True).first()
        if not tree or tree.owner_id == user.pk or tree.members.filter(pk=user.pk).exists():
            raise serializers.ValidationError('This family is no longer available for a request.')
        parent = validate_match_path(tree, candidate['parent'], candidate['grandparent'], candidate['type'], candidate['evidence'])
        gp = Person.objects.get(pk=candidate['grandparent'], family_tree=tree)
        current = JoinRequest.objects.filter(tree=tree, applicant=user, status='PENDING').first()
        if current:
            return current
        data = valid_person_data(payload.get('person', {}), user)
        own_name = normalized(f"{data['first_name']} {data['last_name']}")
        children = Person.objects.filter(relationships_as_person2__person1=parent,
            relationships_as_person2__relationship_type__in=('PARENT', 'ADOPTED', 'STEP'), family_tree=tree).distinct()
        matches = [p for p in children if normalized(str(p)) == own_name and
                   (not data.get('date_of_birth') or not p.date_of_birth or data['date_of_birth'] == p.date_of_birth)]
        if len(matches) > 1:
            raise serializers.ValidationError('Several profiles could match. Ask the owner for an invitation for your profile.')
        return JoinRequest.objects.create(tree=tree, applicant=user, anchor=matches[0] if matches else parent,
            mode='EXISTING' if matches else 'CHILD', evidence={**candidate['evidence'], 'path_parent_id': parent.pk, 'path_grandparent_id': gp.pk, 'path_type': candidate['type']},
            person_data=json.loads(json.dumps(data, cls=DjangoJSONEncoder)))
