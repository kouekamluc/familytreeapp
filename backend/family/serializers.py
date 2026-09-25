from rest_framework import serializers
from .models import FamilyTree, Person, Relationship, Event, Media
from django.contrib.auth import get_user_model
from django.db.models import Q
from .media_access import signed_media_url

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'email', 'username', 'first_name', 'last_name', 'profile_picture']
        read_only_fields = ['id']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['profile_picture'] = signed_media_url(
            instance.profile_picture, self.context.get('request'))
        return data

class PersonSummarySerializer(serializers.ModelSerializer):
    full_name = serializers.SerializerMethodField()
    name = serializers.SerializerMethodField()

    class Meta:
        model = Person
        fields = [
            'id', 'first_name', 'last_name', 'full_name', 'name',
            'gender', 'date_of_birth', 'date_of_death', 'profile_picture',
            'traditional_name', 'village_of_origin', 'clan_totem', 'generation_tier'
        ]

    def get_full_name(self, obj):
        return f"{obj.first_name} {obj.last_name}".strip()

    def get_name(self, obj):
        return f"{obj.first_name} {obj.last_name}".strip()

    def to_representation(self, instance):
        ret = super().to_representation(instance)
        ret['profile_picture'] = signed_media_url(
            instance.profile_picture, self.context.get('request'))
        ret['firstName'] = instance.first_name
        ret['lastName'] = instance.last_name
        ret['birthDate'] = instance.date_of_birth
        ret['deathDate'] = instance.date_of_death
        ret['avatar'] = ret['profile_picture']
        ret['traditionalName'] = instance.traditional_name
        ret['villageOfOrigin'] = instance.village_of_origin
        ret['village'] = instance.village_of_origin or instance.birth_place
        ret['clanTotem'] = instance.clan_totem
        ret['generationTier'] = instance.generation_tier
        return ret

class PersonSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    full_name = serializers.SerializerMethodField()
    parents = serializers.SerializerMethodField()
    children = serializers.SerializerMethodField()
    spouses = serializers.SerializerMethodField()
    siblings = serializers.SerializerMethodField()
    
    class Meta:
        model = Person
        fields = [
            'id', 'user', 'family_tree', 'first_name', 'last_name', 'full_name', 'gender',
            'date_of_birth', 'date_of_death', 'birth_place', 'current_location',
            'traditional_name', 'village_of_origin', 'clan_totem', 'generation_tier',
            'biography', 'is_living', 'profile_picture', 'created_at', 'updated_at',
            'parents', 'children', 'spouses', 'siblings'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
        extra_kwargs = {
            'date_of_birth': {'required': False, 'allow_null': True},
            'family_tree': {'required': False, 'allow_null': True},
            'birth_place': {'required': False, 'allow_blank': True},
            'traditional_name': {'required': False, 'allow_blank': True},
            'village_of_origin': {'required': False, 'allow_blank': True},
            'clan_totem': {'required': False, 'allow_blank': True},
            'gender': {'required': False}
        }
        validators = []

    def to_internal_value(self, data):
        data = data.copy() if hasattr(data, 'copy') else dict(data)
        if 'firstName' in data and 'first_name' not in data:
            data['first_name'] = data['firstName']
        if 'lastName' in data and 'last_name' not in data:
            data['last_name'] = data['lastName']
        if 'birthDate' in data and 'date_of_birth' not in data:
            data['date_of_birth'] = data['birthDate'] or None
        if 'birthPlace' in data and 'birth_place' not in data:
            data['birth_place'] = data['birthPlace']
        if 'deathDate' in data and 'date_of_death' not in data:
            data['date_of_death'] = data['deathDate'] or None
        if 'traditionalName' in data and 'traditional_name' not in data:
            data['traditional_name'] = data['traditionalName']
        if 'villageOfOrigin' in data and 'village_of_origin' not in data:
            data['village_of_origin'] = data['villageOfOrigin']
        elif 'village' in data and 'village_of_origin' not in data:
            data['village_of_origin'] = data['village']
        if 'clanTotem' in data and 'clan_totem' not in data:
            data['clan_totem'] = data['clanTotem']
        elif 'totem' in data and 'clan_totem' not in data:
            data['clan_totem'] = data['totem']
        if 'generationTier' in data and 'generation_tier' not in data:
            data['generation_tier'] = data['generationTier']
        if 'gender' in data and isinstance(data['gender'], str):
            g = data['gender'].lower()
            if g in ('male', 'm'):
                data['gender'] = 'M'
            elif g in ('female', 'f'):
                data['gender'] = 'F'
            elif g in ('other', 'o'):
                data['gender'] = 'O'
        return super().to_internal_value(data)

    def to_representation(self, instance):
        ret = super().to_representation(instance)
        ret['profile_picture'] = signed_media_url(
            instance.profile_picture, self.context.get('request'))
        ret['firstName'] = instance.first_name
        ret['lastName'] = instance.last_name
        ret['name'] = f"{instance.first_name} {instance.last_name}"
        ret['birthDate'] = instance.date_of_birth
        ret['deathDate'] = instance.date_of_death
        ret['birthPlace'] = instance.birth_place
        ret['traditionalName'] = instance.traditional_name
        ret['villageOfOrigin'] = instance.village_of_origin
        ret['village'] = instance.village_of_origin or instance.birth_place
        ret['clanTotem'] = instance.clan_totem
        ret['generationTier'] = instance.generation_tier
        ret['avatar'] = ret['profile_picture']
        return ret
    
    def get_full_name(self, obj):
        return f"{obj.first_name} {obj.last_name}"
    
    def get_parents(self, obj):
        return PersonSummarySerializer(obj.get_parents().filter(family_tree=obj.family_tree),
                                       many=True, context=self.context).data
    
    def get_children(self, obj):
        return PersonSummarySerializer(obj.get_children().filter(family_tree=obj.family_tree),
                                       many=True, context=self.context).data
    
    def get_spouses(self, obj):
        return PersonSummarySerializer(obj.get_spouses().filter(family_tree=obj.family_tree),
                                       many=True, context=self.context).data
    
    def get_siblings(self, obj):
        return PersonSummarySerializer(obj.get_siblings().filter(family_tree=obj.family_tree),
                                       many=True, context=self.context).data

class RelationshipSerializer(serializers.ModelSerializer):
    person1_details = PersonSummarySerializer(source='person1', read_only=True)
    person2_details = PersonSummarySerializer(source='person2', read_only=True)
    
    class Meta:
        model = Relationship
        fields = '__all__'

    def to_representation(self, instance):
        ret = super().to_representation(instance)
        ret['source'] = instance.person1_id
        ret['target'] = instance.person2_id
        return ret

class EventSerializer(serializers.ModelSerializer):
    person_details = PersonSerializer(source='person', read_only=True)
    related_person_details = PersonSerializer(source='related_person', read_only=True)
    
    class Meta:
        model = Event
        fields = '__all__'

class MediaSerializer(serializers.ModelSerializer):
    people_details = PersonSerializer(source='people', many=True, read_only=True)
    uploaded_by_details = UserSerializer(source='uploaded_by', read_only=True)
    
    class Meta:
        model = Media
        fields = '__all__'

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['file'] = signed_media_url(instance.file, self.context.get('request'))
        return data

class FamilyTreeSerializer(serializers.ModelSerializer):
    people = PersonSerializer(many=True, read_only=True)
    owner = serializers.ReadOnlyField(source='owner.username')
    members = serializers.ReadOnlyField(source='members.count')
    
    class Meta:
        model = FamilyTree
        fields = '__all__'
        read_only_fields = ('owner', 'created_at', 'updated_at')
    
    def create(self, validated_data):
        request = self.context.get('request')
        if request and hasattr(request, 'user'):
            validated_data['owner'] = request.user
        tree = super().create(validated_data)
        
        # Check if starting person provided
        if request:
            starting_data = request.data.get('startingPerson') or request.data.get('starting_person')
            if isinstance(starting_data, str):
                import json
                try:
                    starting_data = json.loads(starting_data)
                except Exception:
                    pass
            if starting_data and isinstance(starting_data, dict):
                first_name = starting_data.get('firstName') or starting_data.get('first_name')
                last_name = starting_data.get('lastName') or starting_data.get('last_name')
                if first_name and last_name:
                    gender = starting_data.get('gender', 'M')
                    if isinstance(gender, str) and gender.lower() in ('female', 'f'):
                        gender = 'F'
                    elif isinstance(gender, str) and gender.lower() in ('other', 'o'):
                        gender = 'O'
                    else:
                        gender = 'M'
                    birth_date = starting_data.get('birthDate') or starting_data.get('date_of_birth') or None
                    Person.objects.create(
                        family_tree=tree,
                        first_name=first_name,
                        last_name=last_name,
                        gender=gender,
                        date_of_birth=birth_date if birth_date else None
                    )
        return tree


class FamilyTreeDetailSerializer(FamilyTreeSerializer):
    """Detailed serializer for family tree with all related data."""
    relationships = serializers.SerializerMethodField()
    events = serializers.SerializerMethodField()
    media = serializers.SerializerMethodField()
    
    class Meta(FamilyTreeSerializer.Meta):
        fields = '__all__'
    
    def get_relationships(self, obj):
        relationships = Relationship.objects.filter(
            person1__family_tree=obj, person2__family_tree=obj)
        return RelationshipSerializer(relationships, many=True, context=self.context).data
    
    def get_events(self, obj):
        events = Event.objects.filter(person__family_tree=obj).filter(
            Q(related_person__isnull=True) |
            Q(related_person__family_tree=obj))
        return EventSerializer(events, many=True, context=self.context).data
    
    def get_media(self, obj):
        media = Media.objects.filter(people__family_tree=obj).distinct()
        media = [item for item in media if
                 all(person.family_tree_id == obj.id for person in item.people.all()) and
                 (not item.event or item.event.person.family_tree_id == obj.id)]
        return MediaSerializer(media, many=True, context=self.context).data
