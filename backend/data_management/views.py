from django.shortcuts import render
from rest_framework import views, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.http import HttpResponse
from .resources import (
    PersonResource, RelationshipResource, EventResource,
    MediaResource, TagResource
)
import json
from datetime import datetime

# Create your views here.

class ExportDataView(views.APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request, format=None):
        """Export all family data as JSON."""
        try:
            # Export data from each resource
            person_resource = PersonResource()
            relationship_resource = RelationshipResource()
            event_resource = EventResource()
            media_resource = MediaResource()
            tag_resource = TagResource()
            
            # Get the data
            person_data = person_resource.export().json
            relationship_data = relationship_resource.export().json
            event_data = event_resource.export().json
            media_data = media_resource.export().json
            tag_data = tag_resource.export().json
            
            # Combine all data
            export_data = {
                'people': json.loads(person_data),
                'relationships': json.loads(relationship_data),
                'events': json.loads(event_data),
                'media': json.loads(media_data),
                'tags': json.loads(tag_data),
                'export_date': datetime.now().isoformat(),
                'version': '1.0'
            }
            
            # Create response
            response = HttpResponse(
                json.dumps(export_data, indent=2),
                content_type='application/json'
            )
            response['Content-Disposition'] = f'attachment; filename="family_tree_export_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json"'
            return response
            
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class ImportDataView(views.APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request, format=None):
        """Import family data from JSON."""
        try:
            if 'file' not in request.FILES:
                return Response(
                    {'error': 'No file provided'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Read and parse the JSON file
            file = request.FILES['file']
            import_data = json.loads(file.read())
            
            # Validate the import data structure
            required_keys = ['people', 'relationships', 'events', 'media', 'tags']
            if not all(key in import_data for key in required_keys):
                return Response(
                    {'error': 'Invalid import file format'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Import data using resources
            person_resource = PersonResource()
            relationship_resource = RelationshipResource()
            event_resource = EventResource()
            media_resource = MediaResource()
            tag_resource = TagResource()
            
            # Import each type of data
            results = {
                'people': person_resource.import_data(json.dumps(import_data['people'])),
                'relationships': relationship_resource.import_data(json.dumps(import_data['relationships'])),
                'events': event_resource.import_data(json.dumps(import_data['events'])),
                'media': media_resource.import_data(json.dumps(import_data['media'])),
                'tags': tag_resource.import_data(json.dumps(import_data['tags']))
            }
            
            return Response({
                'message': 'Import completed successfully',
                'results': {
                    'people': results['people'].totals,
                    'relationships': results['relationships'].totals,
                    'events': results['events'].totals,
                    'media': results['media'].totals,
                    'tags': results['tags'].totals
                }
            })
            
        except json.JSONDecodeError:
            return Response(
                {'error': 'Invalid JSON file'},
                status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
