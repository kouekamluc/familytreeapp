from django.shortcuts import render
from django.utils import timezone
from django.db.models import F
from rest_framework import status, generics
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.throttling import ScopedRateThrottle
from django.contrib.auth import authenticate
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from .models import HeritageKey
from .serializers import (
    UserSerializer,
    LoginSerializer,
    HeritageKeySerializer,
    HeritageKeyLoginSerializer,
    RegisterSerializer,
)
import logging

logger = logging.getLogger(__name__)
User = get_user_model()

# Create your views here.

class LoginView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'login'
    
    def post(self, request):
        logger.debug("Received authentication request")
        serializer = LoginSerializer(data=request.data)
        
        if not serializer.is_valid():
            logger.error(f"Login validation errors: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        username = serializer.validated_data['username']
        password = serializer.validated_data['password']
        logger.debug(f"Attempting to authenticate user: {username}")
        
        # First check if user exists
        try:
            user = User.objects.get(username=username)
            logger.debug(f"User found: {user.username}")
            logger.debug(f"User is active: {user.is_active}")
            logger.debug(f"User is staff: {user.is_staff}")
            logger.debug(f"User is superuser: {user.is_superuser}")
            
            # Try authentication
            user = authenticate(request, username=username, password=password)
            if user is None:
                logger.warning(f"Authentication failed for user: {username}")
                return Response({
                    'error': 'Invalid username or password.'
                }, status=status.HTTP_401_UNAUTHORIZED)
            
            if not user.is_active:
                logger.warning(f"Login attempt for disabled user: {username}")
                return Response({
                    'error': 'User account is disabled.'
                }, status=status.HTTP_401_UNAUTHORIZED)
            
            # Generate JWT tokens
            refresh = RefreshToken.for_user(user)
            logger.debug(f"User {username} logged in successfully")
            return Response({
                'user': UserSerializer(user).data,
                'access': str(refresh.access_token),
                'refresh': str(refresh),
                'message': 'Login successful'
            })
            
        except User.DoesNotExist:
            logger.warning(f"User {username} does not exist")
            return Response({
                'error': 'Invalid username or password.'
            }, status=status.HTTP_401_UNAUTHORIZED)


class HeritageKeyLoginView(APIView):
    """
    Authenticate and sign in a family member using only their sacred Heritage Key.
    """
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'heritage_login'

    def post(self, request):
        # Support either 'key' or 'heritage_key' in request payload
        key_value = request.data.get('heritage_key') or request.data.get('key')
        payload = {'key': key_value}
        
        serializer = HeritageKeyLoginSerializer(data=payload)
        if not serializer.is_valid():
            error_msg = serializer.errors.get('key', [serializer.errors.get('non_field_errors', ['Invalid Heritage Key'])])[0]
            if isinstance(error_msg, list):
                error_msg = error_msg[0]
            return Response({
                'error': str(error_msg),
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)

        user = serializer.validated_data['user']
        key_obj = serializer.validated_data['heritage_key_instance']

        # A login key belongs to an existing account; it cannot invite that account
        # into an unrelated tree or claim an unrelated person's profile.
        target_tree = key_obj.family_tree or user.owned_trees.first() or user.shared_trees.first()
        if target_tree and target_tree.owner_id != user.id and not target_tree.members.filter(id=user.id).exists():
            return Response({'error': 'This key no longer grants access to its family tree.'},
                            status=status.HTTP_403_FORBIDDEN)

        # Determine target person in tree (if key is assigned to a specific person or user has one)
        target_person = key_obj.person
        if target_person and (target_person.family_tree_id != (target_tree.id if target_tree else None)
                              or (target_person.user_id and target_person.user_id != user.id)):
            return Response({'error': 'This key is not bound to a valid person.'},
                            status=status.HTTP_403_FORBIDDEN)
        if not target_person:
            from family.models import Person
            target_person = Person.objects.filter(user=user).first()

        HeritageKey.objects.filter(id=key_obj.id).update(
            last_used_at=timezone.now(),
            usage_count=F('usage_count') + 1
        )
        key_obj.refresh_from_db()

        # Generate SimpleJWT tokens
        refresh = RefreshToken.for_user(user)
        logger.info("Heritage Key authentication succeeded for user id %s", user.id)

        tree_info = None
        if target_tree:
            tree_info = {
                'id': target_tree.id,
                'name': target_tree.name,
                'description': target_tree.description,
            }

        return Response({
            'user': UserSerializer(user).data,
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'heritage_key': HeritageKeySerializer(key_obj).data,
            'family_tree': tree_info,
            'person_id': target_person.id if target_person else None,
            'message': f'Welcome to {target_tree.name if target_tree else "the Dynasty"}, {user.first_name or user.username}! Lineage vault unlocked.'
        }, status=status.HTTP_200_OK)


class HeritageKeyMeView(APIView):
    """
    Get all active and past Heritage Keys for the authenticated user.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        keys = request.user.heritage_keys.all()
        return Response(HeritageKeySerializer(keys, many=True).data)


class HeritageKeyGenerateView(APIView):
    """
    Generate a new active Heritage Key for the authenticated user.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        name = request.data.get('name', 'Royal Dynasty Passkey')
        role = request.data.get('role', 'CURATOR' if request.user.is_staff else 'FAMILY_MEMBER')
        if role not in dict(HeritageKey.ROLE_CHOICES):
            return Response({'role': 'Invalid role.'}, status=status.HTTP_400_BAD_REQUEST)
        family_tree_id = request.data.get('family_tree') or request.data.get('family_tree_id')
        person_id = request.data.get('person') or request.data.get('person_id')

        from family.models import FamilyTree, Person
        if family_tree_id:
            try:
                tree = FamilyTree.objects.get(id=family_tree_id)
            except (FamilyTree.DoesNotExist, ValueError, TypeError):
                return Response({'family_tree': 'Tree not found.'}, status=status.HTTP_400_BAD_REQUEST)
            if tree.owner_id != request.user.id and not request.user.is_superuser:
                return Response({'family_tree': 'Only the tree owner can create keys for it.'},
                                status=status.HTTP_403_FORBIDDEN)
        else:
            tree = None

        if person_id:
            try:
                person = Person.objects.get(id=person_id)
            except (Person.DoesNotExist, ValueError, TypeError):
                return Response({'person': 'Person not found.'}, status=status.HTTP_400_BAD_REQUEST)
            if not tree or person.family_tree_id != tree.id or person.user_id != request.user.id:
                return Response({'person': 'A login key can only identify your own profile in this tree.'},
                                status=status.HTTP_403_FORBIDDEN)
        
        new_key_str = HeritageKey.generate_royal_key_string(prefix="KKEVO-ROYAL")
        new_key = HeritageKey.objects.create(
            user=request.user,
            key=new_key_str,
            name=name,
            role=role,
            family_tree_id=family_tree_id,
            person_id=person_id,
            is_active=True
        )
        return Response(HeritageKeySerializer(new_key).data, status=status.HTTP_201_CREATED)


class HeritageKeyRevokeView(APIView):
    """
    Revoke/deactivate a Heritage Key belonging to the authenticated user.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        key_id = request.data.get('key_id')
        key_str = request.data.get('key')
        
        queryset = request.user.heritage_keys.all()
        if key_id:
            key_obj = queryset.filter(id=key_id).first()
        elif key_str:
            key_obj = queryset.filter(key__iexact=key_str).first()
        else:
            return Response({'error': 'Please specify key_id or key.'}, status=status.HTTP_400_BAD_REQUEST)

        if not key_obj:
            return Response({'error': 'Heritage key not found.'}, status=status.HTTP_404_NOT_FOUND)

        key_obj.is_active = False
        key_obj.save()
        return Response({'message': 'Heritage Key revoked.'})


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        try:
            refresh_token = request.data["refresh"]
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response({
                'message': 'Logout successful'
            })
        except Exception as e:
            return Response({
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)

class RegisterView(generics.CreateAPIView):
    permission_classes = [AllowAny]
    serializer_class = RegisterSerializer

class UserView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        return Response(UserSerializer(request.user).data)
