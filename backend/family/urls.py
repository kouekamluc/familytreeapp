from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'trees', views.FamilyTreeViewSet, basename='familytree')
router.register(r'people', views.PersonViewSet, basename='person')
router.register(r'relationships', views.RelationshipViewSet, basename='relationship')
router.register(r'events', views.EventViewSet, basename='event')
router.register(r'media', views.MediaViewSet, basename='media')

urlpatterns = [
    path('', include(router.urls)),
] 