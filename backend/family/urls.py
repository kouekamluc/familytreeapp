from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'people', views.PersonViewSet)
router.register(r'relationships', views.RelationshipViewSet)
router.register(r'events', views.EventViewSet)
router.register(r'media', views.MediaViewSet)

urlpatterns = [
    path('', include(router.urls)),
] 