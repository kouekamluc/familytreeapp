import hashlib
import importlib
import re
from datetime import timedelta
from django.apps import apps
from django.contrib.auth import get_user_model
from django.core import mail
from django.core.cache import cache
from django.test import TestCase, override_settings
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken
from .models import HeritageKey, EmailAction, AccountDeletionRequest
from family.models import FamilyTree, Person

User = get_user_model()

@override_settings(EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend')
class AccountLifecycleTests(TestCase):
    def setUp(self):
        cache.clear()
        self.user = User.objects.create_user(username='account-owner', email='owner@example.test', password='Account-Pass-827!')
        self.client = APIClient()
        self.client.force_authenticate(self.user)

    def code(self):
        return re.search(r'\n\n([0-9a-f]{48})\n', mail.outbox[-1].body)[1]

    def verify(self):
        self.assertEqual(self.client.post('/api/auth/account/', {'action':'verify_email'}, format='json').status_code, 200)
        code = self.code()
        result = self.client.post('/api/auth/account/', {'action':'confirm_email','code':code}, format='json')
        self.assertEqual(result.status_code, 200)
        self.user.refresh_from_db()
        return code

    def test_verification_is_one_time_account_bound_and_not_exposed(self):
        self.client.post('/api/auth/account/', {'action':'verify_email'}, format='json')
        code = self.code()
        action = EmailAction.objects.get()
        self.assertNotEqual(action.digest, code)
        other = User.objects.create_user(username='other', email='other@example.test', password='Other-Pass-728!')
        self.client.force_authenticate(other)
        self.assertEqual(self.client.post('/api/auth/account/', {'action':'confirm_email','code':code}, format='json').status_code, 400)
        self.client.force_authenticate(self.user)
        self.assertEqual(self.client.post('/api/auth/account/', {'action':'confirm_email','code':code}, format='json').status_code, 200)
        self.assertEqual(self.client.post('/api/auth/account/', {'action':'confirm_email','code':code}, format='json').status_code, 400)

    def test_recovery_is_generic_for_unknown_and_unverified_accounts(self):
        self.client.force_authenticate(None)
        results = [self.client.post('/api/auth/recovery/', {'email':email}, format='json') for email in ['missing@example.test','owner@example.test']]
        self.assertEqual(results[0].data, results[1].data)
        self.assertEqual(results[0].status_code, 200)
        self.assertEqual(len(mail.outbox), 0)

    def test_reset_rejects_weak_password_and_invalidates_all_existing_sessions(self):
        self.verify()
        old = RefreshToken.for_user(self.user)
        self.client.force_authenticate(None)
        self.client.post('/api/auth/recovery/', {'email':self.user.email}, format='json')
        code = self.code()
        self.assertEqual(self.client.post('/api/auth/recovery/', {'action':'confirm','code':code,'new_password':'a'}, format='json').status_code, 400)
        self.assertEqual(self.client.post('/api/auth/recovery/', {'action':'confirm','code':code,'new_password':'Wild-Garden-927!'}, format='json').status_code, 200)
        self.assertEqual(self.client.post('/api/auth/token/refresh/', {'refresh':str(old)}, format='json').status_code, 401)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {old.access_token}')
        self.assertEqual(self.client.get('/api/auth/me/').status_code, 401)
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password('Wild-Garden-927!'))
        self.assertEqual(self.client.post('/api/auth/recovery/', {'action':'confirm','code':code,'new_password':'Another-Account-927!'}, format='json').status_code, 400)

    def test_expired_and_reissued_codes_do_not_work(self):
        self.verify()
        self.client.force_authenticate(None)
        self.client.post('/api/auth/recovery/', {'email':self.user.email}, format='json')
        old = self.code()
        self.client.post('/api/auth/recovery/', {'email':self.user.email}, format='json')
        current = self.code()
        self.assertEqual(self.client.post('/api/auth/recovery/', {'action':'confirm','code':old,'new_password':'Account-new-927!'}, format='json').status_code, 400)
        EmailAction.objects.filter(purpose='RESET', used_at=None).update(expires_at=timezone.now()-timedelta(seconds=1))
        self.assertEqual(self.client.post('/api/auth/recovery/', {'action':'confirm','code':current,'new_password':'Account-new-927!'}, format='json').status_code, 400)

    def test_password_change_requires_password_and_revokes_access(self):
        token = RefreshToken.for_user(self.user)
        self.assertEqual(self.client.post('/api/auth/account/', {'action':'change_password','current_password':'wrong','new_password':'Quiet-River-928!'}, format='json').status_code, 400)
        self.assertEqual(self.client.post('/api/auth/account/', {'action':'change_password','current_password':'Account-Pass-827!','new_password':'Quiet-River-928!'}, format='json').status_code, 200)
        self.client.force_authenticate(None)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token.access_token}')
        self.assertEqual(self.client.get('/api/auth/account/').status_code, 401)

    def test_deletion_is_idempotent_review_request_and_never_erases_family(self):
        tree = FamilyTree.objects.create(owner=self.user, name='Shared history')
        person = Person.objects.create(family_tree=tree, first_name='Recorded', last_name='Relative')
        body = {'action':'request_deletion','current_password':'Account-Pass-827!'}
        for _ in range(2):
            self.assertEqual(self.client.post('/api/auth/account/', body, format='json').status_code, 200)
        self.assertEqual(AccountDeletionRequest.objects.count(), 1)
        self.assertTrue(Person.objects.filter(pk=person.pk).exists())
        self.assertTrue(User.objects.filter(pk=self.user.pk).exists())
        self.assertEqual(self.client.post('/api/auth/account/', {'action':'cancel_deletion','current_password':'wrong'}, format='json').status_code, 400)
        self.assertEqual(self.client.post('/api/auth/account/', {'action':'cancel_deletion','current_password':'Account-Pass-827!'}, format='json').status_code, 200)
        self.assertEqual(AccountDeletionRequest.objects.get().status,'CANCELLED')

    def test_public_deletion_page_requires_real_credentials(self):
        from django.test import Client
        browser = Client(enforce_csrf_checks=True)
        page = browser.get('/account/deletion/')
        self.assertEqual(page.status_code, 200)
        self.assertEqual(browser.post('/account/deletion/', {'username':self.user.username,'password':'Account-Pass-827!'}).status_code, 403)
        csrf = browser.cookies['csrftoken'].value
        body = {'username':self.user.username,'password':'Account-Pass-827!','csrfmiddlewaretoken':csrf}
        response = browser.post('/account/deletion/',body)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(AccountDeletionRequest.objects.get().status,'PENDING')

    def test_personal_key_only_revealed_when_created_and_remains_usable(self):
        result = self.client.post('/api/auth/heritage-key/generate/', {'name':'My phone'}, format='json')
        self.assertEqual(result.status_code, 201)
        secret = result.data['key']
        stored = HeritageKey.objects.get(pk=result.data['id'])
        self.assertEqual(stored.key, hashlib.sha256(secret.upper().encode()).hexdigest())
        self.assertNotIn(secret, str(self.client.get('/api/auth/heritage-key/me/').data))
        self.assertNotIn(secret, str(self.client.get('/api/auth/me/').data))
        self.client.force_authenticate(None)
        login = self.client.post('/api/auth/heritage-key/login/', {'key':secret.lower()}, format='json')
        self.assertEqual(login.status_code, 200)
        self.assertNotIn(secret, str(login.data))

    def test_legacy_key_migration_preserves_the_original_login_secret(self):
        key = HeritageKey.objects.create(user=self.user, key='Legacy-Key-123')
        HeritageKey.objects.filter(pk=key.pk).update(key='Legacy-Key-123')
        importlib.import_module('users.migrations.0006_hash_personal_keys').secure_keys(apps, None)
        key.refresh_from_db()
        self.assertEqual(key.key, HeritageKey.verifier('Legacy-Key-123'))
        self.client.force_authenticate(None)
        self.assertEqual(self.client.post('/api/auth/heritage-key/login/', {'key':'Legacy-Key-123'}, format='json').status_code, 200)

    def test_edit_account_cannot_change_email_verification_or_permissions(self):
        result = self.client.post('/api/auth/account/', {'action':'edit_account','current_password':'Account-Pass-827!','first_name':'Changed','last_name':'Owner','email':'attacker@example.test','email_verified':True,'is_staff':True}, format='json')
        self.assertEqual(result.status_code, 200)
        self.user.refresh_from_db()
        self.assertEqual(self.user.email, 'owner@example.test')
        self.assertFalse(self.user.email_verified)
        self.assertFalse(self.user.is_staff)

    def test_case_insensitive_email_conflict_is_rejected_at_registration(self):
        self.client.force_authenticate(None)
        response = self.client.post('/api/auth/register/', {'username': 'second-owner',
            'email': 'OWNER@example.test', 'password': 'Bright-Puzzle-843!',
            'password2': 'Bright-Puzzle-843!', 'first_name': 'New', 'last_name': 'Person'}, format='json')
        self.assertEqual(response.status_code, 400)
        self.assertIn('email', response.data)
        self.assertEqual(User.objects.filter(email__iexact=self.user.email).count(), 1)
