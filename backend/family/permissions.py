from rest_framework import permissions
from .models import FamilyTree, Media


def can_access_tree(user, tree, write=False):
    if tree is None:
        return False
    if not write and tree.is_public:
        return True
    if not user or not user.is_authenticated:
        return False
    return (user.is_superuser or tree.owner_id == user.id or
            tree.members.filter(id=user.id).exists())


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
        trees = object_trees(obj)
        if not trees and isinstance(obj, Media):
            return bool(request.user and request.user.is_authenticated and
                        (request.user.is_superuser or obj.uploaded_by_id == request.user.id))
        return bool(trees) and all(can_access_tree(
            request.user, tree, write=request.method not in permissions.SAFE_METHODS
        ) for tree in trees)
