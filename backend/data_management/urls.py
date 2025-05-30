from django.urls import path
from . import views

urlpatterns = [
    path('export/', views.ExportDataView.as_view(), name='export-data'),
    path('import/', views.ImportDataView.as_view(), name='import-data'),
] 