from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.utils import timezone
from .models import HeritageKey

User = get_user_model()

class HeritageKeySerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    family_tree_name = serializers.CharField(source='family_tree.name', read_only=True)
    person_name = serializers.SerializerMethodField()

    class Meta:
        model = HeritageKey
        fields = (
            'id',
            'key',
            'user',
            'username',
            'name',
            'role',
            'family_tree',
            'family_tree_name',
            'person',
            'person_name',
            'is_active',
            'expires_at',
            'last_used_at',
            'usage_count',
            'created_at',
            'updated_at'
        )
        read_only_fields = ('id', 'created_at', 'updated_at', 'last_used_at', 'usage_count', 'family_tree_name', 'person_name')

    def get_person_name(self, obj):
        return str(obj.person) if obj.person else None


class HeritageKeyLoginSerializer(serializers.Serializer):
    key = serializers.CharField(required=True, trim_whitespace=True)

    def validate_key(self, value):
        cleaned_key = value.strip()
        if not cleaned_key:
            raise serializers.ValidationError("Heritage Key cannot be empty.")
        
        # Case-insensitive lookup
        try:
            key_obj = HeritageKey.objects.select_related('user').get(key__iexact=cleaned_key)
        except HeritageKey.DoesNotExist:
            raise serializers.ValidationError("Invalid Heritage Key. Please check the key and try again.")

        if not key_obj.is_active:
            raise serializers.ValidationError("This Heritage Key has been deactivated or revoked.")

        if key_obj.expires_at and key_obj.expires_at < timezone.now():
            raise serializers.ValidationError("This Heritage Key has expired.")

        if not key_obj.user.is_active:
            raise serializers.ValidationError("Associated user account is disabled.")

        return cleaned_key

    def validate(self, attrs):
        key = attrs.get('key')
        key_obj = HeritageKey.objects.select_related('user').get(key__iexact=key)
        attrs['heritage_key_instance'] = key_obj
        attrs['user'] = key_obj.user
        return attrs


class UserSerializer(serializers.ModelSerializer):
    primary_heritage_key = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name', 'is_staff', 'is_superuser', 'primary_heritage_key')
        read_only_fields = ('id', 'is_staff', 'is_superuser', 'primary_heritage_key')

    def get_primary_heritage_key(self, obj):
        key_obj = obj.heritage_keys.filter(is_active=True).first()
        return key_obj.key if key_obj else None


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField(required=True)
    password = serializers.CharField(required=True, write_only=True)

    def validate(self, data):
        username = data.get('username')
        password = data.get('password')

        if not username or not password:
            raise serializers.ValidationError('Both username and password are required.')

        return data


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True, required=True)

    class Meta:
        model = User
        fields = ('username', 'password', 'password2', 'email', 'first_name', 'last_name')
        extra_kwargs = {
            'first_name': {'required': True},
            'last_name': {'required': True},
            'email': {'required': True}
        }

    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Password fields didn't match."})
        return attrs

    def create(self, validated_data):
        validated_data.pop('password2')
        user = User.objects.create_user(**validated_data)
        # Ensure user gets a default royal heritage key
        user.get_or_create_primary_heritage_key()
        return user
 