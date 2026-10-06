from django.shortcuts import render
from rest_framework import views, status, viewsets
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.decorators import action
from django.http import HttpResponse, FileResponse
from .models import Backup
from .services import BackupService
from .serializers import BackupSerializer
import os

# Create your views here.

class BackupViewSet(viewsets.ModelViewSet):
    queryset = Backup.objects.all()
    serializer_class = BackupSerializer
    permission_classes = [IsAdminUser]
    
    def get_permissions(self):
        return [IsAdminUser()]
    
    @action(detail=False, methods=['post'])
    def create_backup(self, request):
        """Create a new complete disaster-recovery backup."""
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
        """Restore data and media from a backup."""
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
        """Download a backup file (ZIP with media or legacy JSON)."""
        backup = self.get_object()
        
        try:
            stream = BackupService().open_backup(backup)
        except Exception:
            return Response({'error': 'Backup file unavailable.'}, status=status.HTTP_404_NOT_FOUND)
        return FileResponse(stream, as_attachment=True, filename=f'{backup.name}.zip',
                            content_type='application/zip')
