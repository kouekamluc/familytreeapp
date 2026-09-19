from django.shortcuts import render
from rest_framework import status, generics
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.contrib.auth import authenticate
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from .serializers import UserSerializer, LoginSerializer
import logging

logger = logging.getLogger(__name__)
User = get_user_model()

# Create your views here.

class LoginView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        logger.debug(f"Login attempt with data: {request.data}")
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
    serializer_class = UserSerializer

class UserView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        return Response(UserSerializer(request.user).data)
