from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views
from .access_views import FamilyAccessView
from .report_views import ContentReportView

router = DefaultRouter()
router.register(r'trees', views.FamilyTreeViewSet, basename='familytree')
router.register(r'people', views.PersonViewSet, basename='person')
router.register(r'relationships', views.RelationshipViewSet, basename='relationship')
router.register(r'events', views.EventViewSet, basename='event')
router.register(r'media', views.MediaViewSet, basename='media')

urlpatterns = [
    path('content-reports/', ContentReportView.as_view(), name='content_reports'),
    path('family-access/', FamilyAccessView.as_view(), name='family_access'),
    path('', include(router.urls)),
]
