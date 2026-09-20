from rest_framework import permissions
from .models import FamilyTree

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
            return obj.owner == request.user or obj.members.filter(id=request.user.id).exists()

        tree = getattr(obj, 'family_tree', None)
        if tree:
            return tree.owner == request.user or tree.members.filter(id=request.user.id).exists()

        # For Relationship objects with person1 and person2
        p1 = getattr(obj, 'person1', None)
        if p1 and p1.family_tree:
            tree = p1.family_tree
            return tree.owner == request.user or tree.members.filter(id=request.user.id).exists()

        return False


class IsTreeReadable(permissions.BasePermission):
    """
    Allows read access if tree is public, or if user is owner/member.
    Write operations require owner or member status.
    """
    def has_object_permission(self, request, view, obj):
        tree = obj if isinstance(obj, FamilyTree) else getattr(obj, 'family_tree', None)
        if not tree and hasattr(obj, 'person1'):
            p1 = getattr(obj, 'person1', None)
            tree = p1.family_tree if p1 else None

        if tree and tree.is_public and request.method in permissions.SAFE_METHODS:
            return True

        if not request.user or not request.user.is_authenticated:
            return False

        if request.user.is_superuser:
            return True

        if tree:
            is_member = tree.owner == request.user or tree.members.filter(id=request.user.id).exists()
            return is_member

        return False
