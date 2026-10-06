from django.shortcuts import render
from rest_framework import viewsets, permissions, filters, exceptions
from django_filters.rest_framework import DjangoFilterBackend
from .models import Tag
from .serializers import TagSerializer

# Create your views here.

class TagViewSet(viewsets.ModelViewSet):
    queryset = Tag.objects.all()
    serializer_class = TagSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['created_by']
    search_fields = ['name', 'description']
    ordering_fields = ['name', 'created_at']
    
    def perform_create(self, serializer):
        self._validate_links(serializer.validated_data)
        serializer.save(created_by=self.request.user)

    def get_queryset(self):
        return Tag.objects.filter(created_by=self.request.user)

    def _validate_links(self, data):
        from family.permissions import can_access_tree, object_trees
        for person in data.get('people', []):
            if not can_access_tree(self.request.user, person.family_tree, write=True):
                raise exceptions.PermissionDenied('Cannot tag people outside editable trees.')
        for media in data.get('media_items', []):
            trees = object_trees(media)
            if not trees or not all(can_access_tree(self.request.user, tree, write=True) for tree in trees):
                raise exceptions.PermissionDenied('Cannot tag media outside editable trees.')

    def perform_update(self, serializer):
        self._validate_links(serializer.validated_data)
        serializer.save()
