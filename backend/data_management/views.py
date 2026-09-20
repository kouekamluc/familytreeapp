import json
from datetime import datetime
from django.shortcuts import get_object_or_404
from django.http import HttpResponse
from django.db import models, transaction
from django.core import serializers
from rest_framework import views, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from family.models import FamilyTree, Person, Relationship, Event, Media
from tags.models import Tag

class ExportDataView(views.APIView):
    """
    Export family data scoped strictly to trees the authenticated user is authorized to access.
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request, format=None):
        user = request.user
        tree_id = request.query_params.get('tree_id')
        
        # Determine authorized trees
        authorized_trees = FamilyTree.objects.filter(
            models.Q(owner=user) | models.Q(members=user)
        )
        if user.is_superuser:
            authorized_trees = FamilyTree.objects.all()

        if tree_id:
            try:
                tree = FamilyTree.objects.get(id=tree_id)
            except FamilyTree.DoesNotExist:
                return Response({'error': 'Family tree not found.'}, status=status.HTTP_404_NOT_FOUND)
                
            if not authorized_trees.filter(id=tree.id).exists():
                return Response(
                    {'error': 'You do not have permission to export this family tree.'},
                    status=status.HTTP_403_FORBIDDEN
                )
            target_trees = [tree]
        else:
            target_trees = list(authorized_trees.distinct())
            if not target_trees:
                return Response(
                    {'error': 'No authorized family trees found for export.'},
                    status=status.HTTP_404_NOT_FOUND
                )

        try:
            people_qs = Person.objects.filter(family_tree__in=target_trees)
            rels_qs = Relationship.objects.filter(
                person1__family_tree__in=target_trees,
                person2__family_tree__in=target_trees
            ).distinct()
            events_qs = Event.objects.filter(person__family_tree__in=target_trees).distinct()
            media_qs = Media.objects.filter(people__family_tree__in=target_trees).distinct()

            export_data = {
                'family_trees': [{'id': t.id, 'name': t.name, 'description': t.description} for t in target_trees],
                'people': json.loads(serializers.serialize('json', people_qs)),
                'relationships': json.loads(serializers.serialize('json', rels_qs)),
                'events': json.loads(serializers.serialize('json', events_qs)),
                'media': json.loads(serializers.serialize('json', media_qs)),
                'export_date': datetime.now().isoformat(),
                'version': '2.0',
                'exported_by': user.username,
            }
            
            response = HttpResponse(
                json.dumps(export_data, indent=2),
                content_type='application/json'
            )
            filename = f"family_tree_export_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
            response['Content-Disposition'] = f'attachment; filename="{filename}"'
            return response
            
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class ImportDataView(views.APIView):
    """
    Import family data into an authorized target family tree transactionally.
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request, format=None):
        if 'file' not in request.FILES:
            return Response(
                {'error': 'No file provided'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user = request.user
        tree_id = request.data.get('tree_id') or request.query_params.get('tree_id')

        if tree_id:
            try:
                target_tree = FamilyTree.objects.get(id=tree_id)
            except FamilyTree.DoesNotExist:
                return Response({'error': 'Target family tree not found.'}, status=status.HTTP_404_NOT_FOUND)
            
            if target_tree.owner != user and not target_tree.members.filter(id=user.id).exists() and not user.is_superuser:
                return Response(
                    {'error': 'You do not have permission to import data into this family tree.'},
                    status=status.HTTP_403_FORBIDDEN
                )
        else:
            target_tree = FamilyTree.objects.filter(owner=user).first()
            if not target_tree:
                target_tree = FamilyTree.objects.create(name=f"{user.username}'s Lineage", owner=user)

        try:
            file = request.FILES['file']
            import_data = json.loads(file.read())
            
            if 'people' not in import_data or 'relationships' not in import_data:
                return Response(
                    {'error': 'Invalid import file format: missing people or relationships.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Transactionally import people and relationships scoped to target_tree
            with transaction.atomic():
                imported_people_count = 0
                imported_rel_count = 0
                id_mapping = {}

                for p_entry in import_data['people']:
                    fields = p_entry.get('fields', {})
                    old_pk = p_entry.get('pk')
                    
                    person = Person.objects.create(
                        family_tree=target_tree,
                        first_name=fields.get('first_name', ''),
                        last_name=fields.get('last_name', ''),
                        gender=fields.get('gender', 'M'),
                        traditional_name=fields.get('traditional_name', ''),
                        notable_title=fields.get('notable_title', ''),
                        concession_name=fields.get('concession_name', ''),
                        village_of_origin=fields.get('village_of_origin', ''),
                        clan_totem=fields.get('clan_totem', ''),
                        generation_tier=fields.get('generation_tier', 1),
                        is_living=fields.get('is_living', True),
                        date_of_birth=fields.get('date_of_birth'),
                        date_of_death=fields.get('date_of_death'),
                        biography=fields.get('biography', ''),
                    )
                    if old_pk:
                        id_mapping[old_pk] = person.id
                    imported_people_count += 1

                for r_entry in import_data['relationships']:
                    fields = r_entry.get('fields', {})
                    old_p1 = fields.get('person1')
                    old_p2 = fields.get('person2')
                    
                    new_p1 = id_mapping.get(old_p1)
                    new_p2 = id_mapping.get(old_p2)
                    
                    if new_p1 and new_p2:
                        Relationship.objects.create(
                            person1_id=new_p1,
                            person2_id=new_p2,
                            relationship_type=fields.get('relationship_type', 'PARENT'),
                            start_date=fields.get('start_date'),
                            is_active=fields.get('is_active', True),
                        )
                        imported_rel_count += 1

            return Response({
                'message': 'Import completed successfully',
                'target_tree': {
                    'id': target_tree.id,
                    'name': target_tree.name,
                },
                'results': {
                    'people_created': imported_people_count,
                    'relationships_created': imported_rel_count,
                }
            }, status=status.HTTP_201_CREATED)
            
        except json.JSONDecodeError:
            return Response({'error': 'Invalid JSON file.'}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
