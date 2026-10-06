from rest_framework import serializers
from drf_spectacular.utils import extend_schema_field, extend_schema_serializer
from .models import FamilyTree, Person, Relationship, Event, Media
from django.contrib.auth import get_user_model
from django.db.models import Q
from .media_access import signed_media_url

User = get_user_model()

@extend_schema_serializer(component_name='FamilyUserSummary')
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

    def get_full_name(self, obj) -> str:
        return f"{obj.first_name} {obj.last_name}".strip()

    def get_name(self, obj) -> str:
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
            'biography', 'is_living', 'profile_picture', 'created_at', 'updated_at', 'revision',
            'parents', 'children', 'spouses', 'siblings'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'revision', 'search_name']
        extra_kwargs = {
            'date_of_birth': {'required': False, 'allow_null': True},
            'family_tree': {'required': False, 'allow_null': True},
            'birth_place': {'required': False, 'allow_blank': True},
            'traditional_name': {'required': False, 'allow_blank': True},
            'village_of_origin': {'required': False, 'allow_blank': True},
            'clan_totem': {'required': False, 'allow_blank': True},
            'gender': {'required': False, 'default': 'O'}
        }
        validators = []

    def validate_profile_picture(self, upload):
        if upload and upload.size > 10 * 1024 * 1024:
            raise serializers.ValidationError('Portrait exceeds 10 MB.')
        return upload

    def validate(self, attrs):
        from django.core.exceptions import ValidationError
        values = {field.name: getattr(self.instance, field.name)
                  for field in Person._meta.fields} if self.instance else {}
        values.update(attrs)
        candidate = Person(**values)
        try:
            candidate.clean()
        except ValidationError as error:
            raise serializers.ValidationError(getattr(error, 'message_dict', error.messages))
        return attrs

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
    
    def get_full_name(self, obj) -> str:
        return f"{obj.first_name} {obj.last_name}"
    
    @extend_schema_field(PersonSummarySerializer(many=True))
    def get_parents(self, obj):
        return PersonSummarySerializer(obj.get_parents().filter(family_tree=obj.family_tree),
                                       many=True, context=self.context).data
    
    @extend_schema_field(PersonSummarySerializer(many=True))
    def get_children(self, obj):
        return PersonSummarySerializer(obj.get_children().filter(family_tree=obj.family_tree),
                                       many=True, context=self.context).data
    
    @extend_schema_field(PersonSummarySerializer(many=True))
    def get_spouses(self, obj):
        return PersonSummarySerializer(obj.get_spouses().filter(family_tree=obj.family_tree),
                                       many=True, context=self.context).data
    
    @extend_schema_field(PersonSummarySerializer(many=True))
    def get_siblings(self, obj):
        return PersonSummarySerializer(obj.get_siblings().filter(family_tree=obj.family_tree),
                                       many=True, context=self.context).data

class PersonGraphSerializer(PersonSerializer):
    """All editable person fields, without duplicating the graph inside every row."""
    class Meta(PersonSerializer.Meta):
        fields = [name for name in PersonSerializer.Meta.fields
                  if name not in ('parents', 'children', 'spouses', 'siblings')]


class RelationshipSerializer(serializers.ModelSerializer):
    person1_details = PersonSummarySerializer(source='person1', read_only=True)
    person2_details = PersonSummarySerializer(source='person2', read_only=True)
    
    class Meta:
        model = Relationship
        fields = '__all__'
        read_only_fields = ['revision']

    def validate(self, attrs):
        from django.core.exceptions import ValidationError
        values = {field.name: getattr(self.instance, field.name)
                  for field in Relationship._meta.fields} if self.instance else {}
        values.update(attrs)
        candidate = Relationship(**values)
        try:
            candidate.clean()
        except ValidationError as error:
            raise serializers.ValidationError(getattr(error, 'message_dict', error.messages))
        return attrs

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

    def validate(self, attrs):
        from django.core.exceptions import ValidationError
        values = {field.name: getattr(self.instance, field.name)
                  for field in Event._meta.fields} if self.instance else {}
        values.update(attrs)
        try:
            Event(**values).clean()
        except ValidationError as error:
            raise serializers.ValidationError(getattr(error, 'message_dict', error.messages))
        return attrs

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
    owner = serializers.CharField(source='owner.username', read_only=True)
    members = serializers.IntegerField(source='members.count', read_only=True)
    people_count = serializers.IntegerField(source='people.count', read_only=True)
    can_edit = serializers.SerializerMethodField()
    can_manage = serializers.SerializerMethodField()

    def validate_is_public(self, value):
        from django.conf import settings
        if value and not settings.ALLOW_PUBLIC_FAMILY_READS:
            raise serializers.ValidationError('Families are private. Use an invitation to grant access.')
        return value

    def to_representation(self, instance):
        from django.conf import settings
        data = super().to_representation(instance)
        if not settings.ALLOW_PUBLIC_FAMILY_READS:
            data['is_public'] = False
        return data

    def get_can_edit(self, obj) -> bool:
        from .permissions import can_access_tree
        request = self.context.get('request')
        return bool(request and can_access_tree(request.user, obj, write=True))

    def get_can_manage(self, obj) -> bool:
        request = self.context.get('request')
        user = request.user if request else None
        return bool(user and user.is_authenticated and
                    (user.is_superuser or obj.owner_id == user.id))
    
    class Meta:
        model = FamilyTree
        fields = '__all__'
        read_only_fields = ('owner', 'created_at', 'updated_at')
    
    def create(self, validated_data):
        request = self.context.get('request')
        if request and hasattr(request, 'user'):
            validated_data['owner'] = request.user
        tree = super().create(validated_data)
        
        if request:
            starting_data = request.data.get('startingPerson') or request.data.get('starting_person')
            if starting_data is not None:
                if isinstance(starting_data, str):
                    import json
                    try:
                        starting_data = json.loads(starting_data)
                    except (ValueError, TypeError):
                        raise serializers.ValidationError({'starting_person': 'Provide a valid person object.'})
                if not isinstance(starting_data, dict):
                    raise serializers.ValidationError({'starting_person': 'Provide a valid person object.'})
                person = PersonSerializer(data=starting_data, context=self.context)
                person.is_valid(raise_exception=True)
                person.save(family_tree=tree)
        return tree


class FamilyTreeListSerializer(FamilyTreeSerializer):
    """The chooser needs tree metadata, not repeated copies of every person's family."""
    class Meta(FamilyTreeSerializer.Meta):
        fields = ['id', 'name', 'description', 'owner', 'members', 'is_public',
                  'created_at', 'updated_at', 'people_count', 'can_edit', 'can_manage', 'discovery_enabled']


class FamilyTreeDetailSerializer(FamilyTreeSerializer):
    """Detailed serializer for family tree with all related data."""
    relationships = serializers.SerializerMethodField()
    events = serializers.SerializerMethodField()
    media = serializers.SerializerMethodField()
    
    class Meta(FamilyTreeSerializer.Meta):
        fields = '__all__'
    
    @extend_schema_field(RelationshipSerializer(many=True))
    def get_relationships(self, obj):
        relationships = Relationship.objects.filter(
            person1__family_tree=obj, person2__family_tree=obj)
        return RelationshipSerializer(relationships, many=True, context=self.context).data
    
    @extend_schema_field(EventSerializer(many=True))
    def get_events(self, obj):
        events = Event.objects.filter(person__family_tree=obj).filter(
            Q(related_person__isnull=True) |
            Q(related_person__family_tree=obj))
        return EventSerializer(events, many=True, context=self.context).data
    
    @extend_schema_field(MediaSerializer(many=True))
    def get_media(self, obj):
        media = Media.objects.filter(people__family_tree=obj).distinct()
        media = [item for item in media if
                 all(person.family_tree_id == obj.id for person in item.people.all()) and
                 (not item.event or item.event.person.family_tree_id == obj.id)]
        return MediaSerializer(media, many=True, context=self.context).data
