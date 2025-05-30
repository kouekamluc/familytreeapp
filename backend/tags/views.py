from django.shortcuts import render
from rest_framework import viewsets, permissions, filters
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
        serializer.save(created_by=self.request.user)
