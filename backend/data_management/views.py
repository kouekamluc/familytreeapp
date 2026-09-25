import json
from datetime import datetime
from django.http import HttpResponse
from django.db import models, transaction
from django.core.exceptions import ValidationError as DjangoValidationError
from django.core import serializers
from rest_framework import views, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from family.models import FamilyTree, Person, Relationship, Event, Media

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
            media_count = Media.objects.filter(people__family_tree__in=target_trees).distinct().count()

            export_data = {
                'family_trees': [{'id': t.id, 'name': t.name, 'description': t.description} for t in target_trees],
                'people': json.loads(serializers.serialize('json', people_qs)),
                'relationships': json.loads(serializers.serialize('json', rels_qs)),
                'events': json.loads(serializers.serialize('json', events_qs)),
                'media_omitted': media_count,
                'note': 'JSON export contains people, relationships and events. Use an admin backup for media files.',
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
            
            if target_tree.owner_id != user.id and not user.is_superuser:
                return Response(
                    {'error': 'Only the tree owner can import data into this family tree.'},
                    status=status.HTTP_403_FORBIDDEN
                )
        else:
            target_tree = FamilyTree.objects.filter(owner=user).first()

        try:
            file = request.FILES['file']
            if file.size > 10 * 1024 * 1024:
                return Response({'error': 'Import file exceeds 10 MB.'}, status=status.HTTP_400_BAD_REQUEST)
            import_data = json.loads(file.read())
            
            if (not isinstance(import_data, dict) or
                not all(isinstance(import_data.get(key), list) for key in ('people', 'relationships'))):
                return Response(
                    {'error': 'Invalid import file format: missing people or relationships.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            if import_data.get('media'):
                return Response({'error': 'Media files need a separate upload; this JSON import cannot restore them.'},
                                status=status.HTTP_400_BAD_REQUEST)
            if not isinstance(import_data.get('events', []), list):
                return Response({'error': 'Invalid events section.'}, status=status.HTTP_400_BAD_REQUEST)
            
            # Transactionally import people and relationships scoped to target_tree
            with transaction.atomic():
                if target_tree is None:
                    target_tree = FamilyTree.objects.create(name=f"{user.username}'s Lineage", owner=user)
                imported_people_count = 0
                imported_rel_count = 0
                imported_event_count = 0
                id_mapping = {}

                for p_entry in import_data['people']:
                    if not isinstance(p_entry, dict) or not isinstance(p_entry.get('fields'), dict):
                        raise ValueError('Invalid person entry.')
                    fields = p_entry.get('fields', {})
                    old_pk = p_entry.get('pk')
                    
                    person = Person(
                        family_tree=target_tree,
                        first_name=fields.get('first_name', ''),
                        last_name=fields.get('last_name', ''),
                        gender=fields.get('gender', 'M'),
                        traditional_name=fields.get('traditional_name', ''),
                        birth_place=fields.get('birth_place', ''),
                        current_location=fields.get('current_location', ''),
                        village_of_origin=fields.get('village_of_origin', ''),
                        clan_totem=fields.get('clan_totem', ''),
                        generation_tier=fields.get('generation_tier', 1),
                        is_living=fields.get('is_living', True),
                        date_of_birth=fields.get('date_of_birth'),
                        date_of_death=fields.get('date_of_death'),
                        biography=fields.get('biography', ''),
                    )
                    person.full_clean()
                    person.save()
                    if old_pk is not None:
                        id_mapping[str(old_pk)] = person.id
                    imported_people_count += 1

                for r_entry in import_data['relationships']:
                    if not isinstance(r_entry, dict) or not isinstance(r_entry.get('fields'), dict):
                        raise ValueError('Invalid relationship entry.')
                    fields = r_entry.get('fields', {})
                    old_p1 = fields.get('person1')
                    old_p2 = fields.get('person2')
                    
                    new_p1 = id_mapping.get(str(old_p1))
                    new_p2 = id_mapping.get(str(old_p2))
                    
                    if not new_p1 or not new_p2:
                        raise ValueError('A relationship references a person missing from this import.')
                    relationship = Relationship(
                        person1_id=new_p1,
                        person2_id=new_p2,
                        relationship_type=fields.get('relationship_type', 'PARENT'),
                        start_date=fields.get('start_date'),
                        end_date=fields.get('end_date'),
                        is_current=fields.get('is_current', True),
                        notes=fields.get('notes', ''),
                    )
                    relationship.full_clean()
                    relationship.save()
                    imported_rel_count += 1

                for e_entry in import_data.get('events', []):
                    if not isinstance(e_entry, dict) or not isinstance(e_entry.get('fields'), dict):
                        raise ValueError('Invalid event entry.')
                    fields = e_entry.get('fields', {})
                    person_id = id_mapping.get(str(fields.get('person')))
                    related_id = (id_mapping.get(str(fields.get('related_person')))
                                  if fields.get('related_person') is not None else None)
                    if not person_id or (fields.get('related_person') is not None and not related_id):
                        raise ValueError('An event references a person missing from this import.')
                    event = Event(
                        person_id=person_id,
                        related_person_id=related_id,
                        event_type=fields.get('event_type', 'OTHER'),
                        date=fields.get('date'),
                        location=fields.get('location', ''),
                        description=fields.get('description', ''),
                    )
                    event.full_clean()
                    event.save()
                    imported_event_count += 1

            return Response({
                'message': 'Import completed successfully',
                'target_tree': {
                    'id': target_tree.id,
                    'name': target_tree.name,
                },
                'results': {
                    'people_created': imported_people_count,
                    'relationships_created': imported_rel_count,
                    'events_created': imported_event_count,
                }
            }, status=status.HTTP_201_CREATED)
            
        except json.JSONDecodeError:
            return Response({'error': 'Invalid JSON file.'}, status=status.HTTP_400_BAD_REQUEST)
        except (ValueError, DjangoValidationError) as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
