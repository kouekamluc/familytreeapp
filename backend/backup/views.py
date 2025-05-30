from django.shortcuts import render
from rest_framework import views, status, viewsets
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.decorators import action
from django.http import HttpResponse
from .models import Backup
from .services import BackupService
from .serializers import BackupSerializer
import os

# Create your views here.

class BackupViewSet(viewsets.ModelViewSet):
    queryset = Backup.objects.all()
    serializer_class = BackupSerializer
    permission_classes = [IsAuthenticated]
    
    def get_permissions(self):
        if self.action in ['create', 'restore', 'destroy']:
            return [IsAdminUser()]
        return [IsAuthenticated()]
    
    @action(detail=False, methods=['post'])
    def create_backup(self, request):
        """Create a new backup."""
        try:
            backup_service = BackupService()
            backup = backup_service.create_backup(user=request.user)
            return Response(BackupSerializer(backup).data)
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=True, methods=['post'])
    def restore(self, request, pk=None):
        """Restore data from a backup."""
        try:
            backup_service = BackupService()
            backup_service.restore_backup(pk)
            return Response({'message': 'Backup restored successfully'})
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=True, methods=['get'])
    def download(self, request, pk=None):
        """Download a backup file."""
        backup = self.get_object()
        
        if not os.path.exists(backup.file_path):
            return Response(
                {'error': 'Backup file not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        with open(backup.file_path, 'rb') as f:
            response = HttpResponse(f.read(), content_type='application/json')
            response['Content-Disposition'] = f'attachment; filename="{backup.name}.json"'
            return response
