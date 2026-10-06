from rest_framework import permissions
from django.conf import settings
from django.db.models import Q
from .models import FamilyTree, Media, TreeMembership


def readable_trees(user):
    """One boundary for list and detail access, including legacy public flags."""
    public = Q(is_public=True) if settings.ALLOW_PUBLIC_FAMILY_READS else Q(pk__in=[])
    if not user or not user.is_authenticated:
        return FamilyTree.objects.filter(public)
    if user.is_superuser:
        return FamilyTree.objects.all()
    return FamilyTree.objects.filter(Q(owner=user) | Q(members=user) | public).distinct()


def can_access_tree(user, tree, write=False):
    if tree is None:
        return False
    if not write and tree.is_public and settings.ALLOW_PUBLIC_FAMILY_READS:
        return True
    if not user or not user.is_authenticated:
        return False
    if user.is_superuser or tree.owner_id == user.id:
        return True
    if not tree.members.filter(id=user.id).exists():
        return False
    # Legacy approved members keep editing rights until an explicit role exists.
    membership = TreeMembership.objects.filter(tree=tree, user=user).first()
    return not write or membership is None or membership.role == 'EDITOR'


def object_trees(obj):
    if isinstance(obj, FamilyTree):
        return [obj]
    if isinstance(obj, Media):
        trees = list(FamilyTree.objects.filter(people__media_items=obj).distinct())
        if obj.event_id:
            trees.append(obj.event.person.family_tree)
        return trees
    if hasattr(obj, 'family_tree'):
        return [obj.family_tree]
    if hasattr(obj, 'person1'):
        return [obj.person1.family_tree, obj.person2.family_tree]
    if hasattr(obj, 'person'):
        trees = [obj.person.family_tree]
        if obj.related_person_id:
            trees.append(obj.related_person.family_tree)
        return trees
    return []

class IsTreeOwner(permissions.BasePermission):
    """
    Allows access only to the owner of the family tree.
    """
    def has_object_permission(self, request, view, obj):
        if not request.user or not request.user.is_authenticated:
            return False
        if isinstance(obj, FamilyTree):
            return obj.owner == request.user or request.user.is_superuser
        tree = getattr(obj, 'family_tree', None)
        if tree:
            return tree.owner == request.user or request.user.is_superuser
        return False


class IsTreeEditor(permissions.BasePermission):
    """
    Allows write access to owners and approved members of the family tree.
    """
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated

    def has_object_permission(self, request, view, obj):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.is_superuser:
            return True

        if isinstance(obj, FamilyTree):
            return can_access_tree(request.user, obj, write=True)

        tree = getattr(obj, 'family_tree', None)
        if tree:
            return can_access_tree(request.user, tree, write=True)

        # For Relationship objects with person1 and person2
        p1 = getattr(obj, 'person1', None)
        if p1 and p1.family_tree:
            tree = p1.family_tree
            return can_access_tree(request.user, tree, write=True)

        return False


class IsTreeReadable(permissions.BasePermission):
    """
    Allows read access if tree is public, or if user is owner/member.
    Write operations require owner or member status.
    """
    def has_object_permission(self, request, view, obj):
        trees = object_trees(obj)
        if not trees and isinstance(obj, Media):
            return bool(request.user and request.user.is_authenticated and
                        (request.user.is_superuser or obj.uploaded_by_id == request.user.id))
        return bool(trees) and all(can_access_tree(
            request.user, tree, write=request.method not in permissions.SAFE_METHODS
        ) for tree in trees)
