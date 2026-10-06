"""Account lifecycle actions. Email secrets never appear in API responses."""
import hashlib
import secrets
from datetime import timedelta
from django.conf import settings
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.mail import send_mail
from django.db import transaction
from django.utils import timezone
from django.utils.crypto import constant_time_compare
from rest_framework import serializers
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.throttling import ScopedRateThrottle
from rest_framework_simplejwt.serializers import TokenRefreshSerializer
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.settings import api_settings
from rest_framework_simplejwt.utils import get_md5_hash_password
from rest_framework.exceptions import AuthenticationFailed
from .models import EmailAction, AccountDeletionRequest
from .serializers import UserSerializer
import logging

User = get_user_model()
logger = logging.getLogger(__name__)
GENERIC = 'If this is a verified account, a recovery code will be sent to its email.'


def stamp(user):
    return hashlib.sha256(f'{user.password}|{user.email}'.encode()).hexdigest()


def issue(user, purpose):
    code = secrets.token_hex(24)
    with transaction.atomic():
        user = User.objects.select_for_update().get(pk=user.pk)
        EmailAction.objects.filter(user=user, purpose=purpose, used_at=None).update(used_at=timezone.now())
        EmailAction.objects.create(user=user, purpose=purpose,
            digest=hashlib.sha256(code.encode()).hexdigest(), account_stamp=stamp(user),
            expires_at=timezone.now() + timedelta(minutes=30))
    label = {'VERIFY': 'Verify your email', 'RESET': 'Reset your password', 'DELETE': 'Request account deletion'}[purpose]
    send_mail(f'Kkevo Family: {label}',
        f'{label} in Kkevo Family using this code:\n\n{code}\n\n'
        'The code expires in 30 minutes and can be used once. '
        'If you did not request it, ignore this email. Never share this code.',
        settings.DEFAULT_FROM_EMAIL, [user.email], fail_silently=False)


def consume(code, purpose, apply, expected_user=None):
    digest = hashlib.sha256(code.strip().encode()).hexdigest()
    candidate = EmailAction.objects.filter(digest=digest, purpose=purpose).first()
    if candidate is None:
        raise serializers.ValidationError('This code is invalid or expired. Request a new code.')
    with transaction.atomic():
        user = User.objects.select_for_update().filter(pk=candidate.user_id).first()
        action = EmailAction.objects.select_for_update().filter(pk=candidate.pk).first()
        if (not user or not action or not user.is_active or action.used_at or action.expires_at <= timezone.now()
            or not constant_time_compare(action.account_stamp, stamp(user))
            or (expected_user is not None and user.pk != expected_user)):
            raise serializers.ValidationError('This code is invalid or expired. Request a new code.')
        apply(user)
        action.used_at = timezone.now()
        action.save(update_fields=['used_at'])


def password_change(user, password):
    from django.core.exceptions import ValidationError
    try:
        validate_password(password, user)
    except ValidationError as error:
        raise serializers.ValidationError({'new_password': error.messages})
    user.set_password(password)
    user.save(update_fields=['password'])
    # Refresh tokens must not survive a credential reset, including on other phones.
    from rest_framework_simplejwt.token_blacklist.models import OutstandingToken, BlacklistedToken
    for token in OutstandingToken.objects.filter(user=user):
        BlacklistedToken.objects.get_or_create(token=token)


class SecureRefreshSerializer(TokenRefreshSerializer):
    def validate(self, attrs):
        token = RefreshToken(attrs['refresh'])
        user = User.objects.filter(pk=token.get(api_settings.USER_ID_CLAIM)).first()
        if (not user or not user.is_active or not constant_time_compare(
                token.get(api_settings.REVOKE_TOKEN_CLAIM, ''), get_md5_hash_password(user.password))):
            raise AuthenticationFailed('Sign in again to continue.')
        return super().validate(attrs)


class AccountActionView(APIView):
    permission_classes = [IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'account_action'

    def get(self, request):
        deletion = AccountDeletionRequest.objects.filter(user=request.user).first()
        return Response({'user': UserSerializer(request.user).data,
            'deletion_status': deletion.status if deletion else None,
            'owned_families': list(request.user.owned_trees.values('id', 'name'))})

    def post(self, request):
        if not isinstance(request.data, dict):
            raise serializers.ValidationError('Choose a valid account action.')
        action = request.data.get('action')
        user = request.user
        if action == 'confirm_email':
            def verify(locked):
                locked.email_verified = True
                locked.save(update_fields=['email_verified'])
            consume(str(request.data.get('code', '')), 'VERIFY', verify, user.pk)
        elif action == 'verify_email':
            if not user.email_verified:
                try:
                    issue(user, 'VERIFY')
                except Exception:
                    logger.error('Verification mail delivery failed')
                    return Response({'error': 'Unable to send the code. Try again.'}, status=503)
            return Response({'message': 'Check your email for the verification code.'})
        elif action in ('change_password', 'edit_account', 'request_deletion', 'cancel_deletion'):
            with transaction.atomic():
                user = User.objects.select_for_update().get(pk=user.pk)
                if not user.check_password(str(request.data.get('current_password', ''))):
                    raise serializers.ValidationError({'current_password': 'Your current password is incorrect.'})
                if action == 'change_password':
                    password_change(user, str(request.data.get('new_password', '')))
                    return Response({'message': 'Password changed. Sign in again on your devices.'})
                if action == 'edit_account':
                    class Identity(serializers.Serializer):
                        first_name = serializers.CharField(max_length=30)
                        last_name = serializers.CharField(max_length=30)
                    form = Identity(data=request.data)
                    form.is_valid(raise_exception=True)
                    user.first_name = form.validated_data['first_name']
                    user.last_name = form.validated_data['last_name']
                    user.save(update_fields=['first_name', 'last_name'])
                elif action == 'request_deletion':
                    deletion, _ = AccountDeletionRequest.objects.get_or_create(user=user)
                    if deletion.status == 'CANCELLED':
                        deletion.status = 'PENDING'
                        deletion.save(update_fields=['status', 'updated_at'])
                    return Response({'message': 'Deletion requested. Pending review; no records have been deleted.', 'status': 'PENDING'})
                else:
                    AccountDeletionRequest.objects.filter(user=user, status='PENDING').update(status='CANCELLED', updated_at=timezone.now())
        else:
            raise serializers.ValidationError('Choose a valid account action.')
        return Response({'user': UserSerializer(user).data})


class RecoveryView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'account_recovery'

    def post(self, request):
        if not isinstance(request.data, dict):
            raise serializers.ValidationError('Choose a valid account action.')
        action = request.data.get('action', 'request')
        if action == 'confirm':
            password = str(request.data.get('new_password', ''))
            consume(str(request.data.get('code', '')), 'RESET', lambda user: password_change(user, password))
            return Response({'message': 'Password reset. Sign in with your new password.'})
        form = serializers.EmailField()
        email = form.run_validation(request.data.get('email', ''))
        user = User.objects.filter(email__iexact=email, email_verified=True, is_active=True).first()
        if user:
            try:
                issue(user, 'RESET')
            except Exception:
                logger.error('Recovery mail delivery failed')
        return Response({'message': GENERIC})
