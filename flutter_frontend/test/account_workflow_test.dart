import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_frontend/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_frontend/config/royal_theme.dart';
import 'package:flutter_frontend/l10n/app_strings.dart';
import 'package:flutter_frontend/models/heritage_key.dart';
import 'package:flutter_frontend/providers/auth_provider.dart';
import 'package:flutter_frontend/services/api_service.dart';
import 'package:flutter_frontend/views/auth/account_settings_view.dart';
import 'package:flutter_frontend/views/auth/recovery_view.dart';
import 'package:flutter_frontend/views/vault/heritage_vault_view.dart';
import 'workflow_ui_test.dart' show WorkflowApi;
import 'package:flutter_frontend/models/user.dart';
import 'package:flutter_frontend/services/local_storage_service.dart';

class AccountApi extends WorkflowApi {
  String? deletion;
  bool reject = false;
  int calls = 0;
  Map<String, dynamic>? lastAction;
  Completer<Map<String, dynamic>?>? pending;
  @override
  Future<Map<String, dynamic>?> accountDetails() async => {
    'deletion_status': deletion,
    'owned_families': [],
  };
  @override
  Future<Map<String, dynamic>?> accountAction(Map<String, dynamic> data) async {
    calls++;
    lastAction = data;
    if (pending != null) return pending!.future;
    if (reject) {
      lastError = 'Your current password is incorrect.';
      return null;
    }
    if (data['action'] == 'request_deletion') deletion = 'PENDING';
    if (data['action'] == 'cancel_deletion') deletion = 'CANCELLED';
    return {};
  }

  @override
  Future<Map<String, dynamic>?> recoverAccount(
    Map<String, dynamic> data,
  ) async {
    calls++;
    if (pending != null) return pending!.future;
    if (data['action'] == 'confirm') {
      lastError = 'This code is invalid or expired. Request a new code.';
      return null;
    }
    return {};
  }

  @override
  Future<List<HeritageKey>> getHeritageKeys() async => [];
  @override
  Future<HeritageKey?> generateHeritageKey({
    String? name,
    String? role,
  }) async => HeritageKey(
    id: 7,
    key: 'PRIVATE-ONCE-ONLY',
    name: name ?? '',
    role: role ?? 'FAMILY_MEMBER',
    isActive: true,
    usageCount: 0,
  );
}

void main() {
  test('legacy metadata cannot reintroduce a saved personal secret', () {
    final account = SavedAccount.fromJson({
      'user_id': 1,
      'username': 'owner',
      'heritage_key': 'OLD-SECRET',
    });
    expect(account.heritageKey, isNull);
    expect(account.toJson().containsKey('heritage_key'), isFalse);
    final user = User.fromJson({'id': 1, 'primary_heritage_key': 'OLD-SECRET'});
    expect(user.primaryHeritageKey, isNull);
    expect(user.toJson().containsKey('primary_heritage_key'), isFalse);
  });

  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });
  Future<AuthProvider> pump(
    WidgetTester t,
    AccountApi api,
    Widget screen, {
    String locale = 'en',
    double scale = 1,
  }) async {
    t.view.physicalSize = const Size(360, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final auth = AuthProvider(api);
    await t.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: MaterialApp(
          theme: RoyalTheme.lightTheme,
          locale: Locale(locale),
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: const [
            AppStrings.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (ctx, child) => MediaQuery(
            data: MediaQuery.of(
              ctx,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: screen,
        ),
      ),
    );
    await t.pumpAndSettle();
    return auth;
  }

  Future<void> tap(WidgetTester t, String text) async {
    final f = find.text(text).last;
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  Future<void> fill(WidgetTester t, String label, String value) async {
    final f = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == label,
    );
    await t.ensureVisible(f);
    await t.enterText(f, value);
    await t.pump();
  }

  test(
    'real account and recovery methods use mounted routes and readable errors',
    () async {
      await ApiConfig.setBaseUrl('https://account.example/api');
      final api = ApiService();
      await api.init();
      await http.runWithClient(
        () async {
          expect(await api.login('owner', 'Secret-834!'), isTrue);
          expect((await api.accountDetails())?['deletion_status'], 'PENDING');
          expect(
            await api.accountAction({'action': 'request_deletion'}),
            isNull,
          );
          expect(api.lastError, 'Your current password is incorrect.');
          expect(
            await api.recoverAccount({'email': 'owner@example.test'}),
            isNotNull,
          );
        },
        () => MockClient((request) async {
          switch (request.url.path) {
            case '/api/auth/token/':
              return http.Response(
                '{"access":"access","refresh":"refresh"}',
                200,
              );
            case '/api/users/me/':
              return http.Response(
                '{"id":1,"username":"owner","email":"owner@example.test"}',
                200,
              );
            case '/api/auth/account/':
              expect(request.headers['authorization'], 'Bearer access');
              return request.method == 'GET'
                  ? http.Response('{"deletion_status":"PENDING"}', 200)
                  : http.Response(
                      '{"current_password":["Your current password is incorrect."]}',
                      400,
                    );
            case '/api/auth/recovery/':
              expect(request.headers.containsKey('authorization'), isFalse);
              expect(jsonDecode(request.body)['email'], 'owner@example.test');
              return http.Response('{"message":"Check your email"}', 200);
            default:
              fail('Unrecognized route: ${request.url.path}');
          }
        }),
      );
    },
  );

  testWidgets(
    'recovery accepts an email and keeps code/password after rejection',
    (t) async {
      final api = AccountApi();
      await pump(t, api, const RecoveryView());
      await fill(t, 'Account email', 'someone@example.test');
      await tap(t, 'Send recovery code');
      expect(api.calls, 1);
      await fill(t, 'Email code', 'expired-code');
      await fill(t, 'New password', 'Secure-Selection-834!');
      await fill(t, 'Confirm new password', 'Secure-Selection-834!');
      await tap(t, 'Reset password');
      expect(api.calls, 2);
      expect(find.text('expired-code'), findsOneWidget);
      expect(
        find.text('This code is invalid or expired. Request a new code.'),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'deletion can be requested and cancelled; failed password keeps dialog',
    (t) async {
      final api = AccountApi();
      await pump(t, api, const AccountSettingsView());
      await tap(t, 'Request account deletion');
      api.reject = true;
      await fill(t, 'Current password', 'wrong');
      await tap(t, 'Request account deletion');
      expect(find.text('Your current password is incorrect.'), findsOneWidget);
      expect(find.text('wrong'), findsOneWidget);
      api.reject = false;
      await tap(t, 'Request account deletion');
      expect(
        find.text(
          'Deletion requested. Pending review; no records have been deleted.',
        ),
        findsOneWidget,
      );
      await tap(t, 'Cancel deletion request');
      await fill(t, 'Current password', 'valid-password');
      await tap(t, 'Cancel deletion request');
      expect(api.deletion, 'CANCELLED');
      expect(find.text('Request account deletion'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('account switch during recovery unlocks the screen safely', (
    t,
  ) async {
    final api = AccountApi()..pending = Completer<Map<String, dynamic>?>();
    await pump(t, api, const RecoveryView());
    await fill(t, 'Account email', 'someone@example.test');
    await t.tap(find.text('Send recovery code'));
    await t.pump();
    api.signedIn = false;
    api.pending!.complete({});
    await t.pumpAndSettle();
    expect(
      find.text('The account has changed. Close this form.'),
      findsOneWidget,
    );
    expect(t.widget<PopScope>(find.byType(PopScope).first).canPop, isTrue);
  });

  testWidgets('key secret is revealed once and not stored in provider list', (
    t,
  ) async {
    final api = AccountApi();
    final auth = await pump(t, api, const HeritageVaultView());
    await tap(t, 'Create a personal key');
    await fill(t, 'Key name *', 'My phone');
    await tap(t, 'Create key');
    expect(find.text('PRIVATE-ONCE-ONLY'), findsOneWidget);
    expect(auth.heritageKeys.single.key, isNot('PRIVATE-ONCE-ONLY'));
    await tap(t, 'Done');
    expect(find.text('PRIVATE-ONCE-ONLY'), findsNothing);
    expect(find.text('My phone'), findsOneWidget);
    expect(find.text('Copy'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'loaded account details are hidden immediately after switching accounts',
    (t) async {
      final api = AccountApi()..deletion = 'PENDING';
      await pump(t, api, const AccountSettingsView());
      expect(
        find.text(
          'Deletion requested. Pending review; no records have been deleted.',
        ),
        findsOneWidget,
      );
      api.signedIn = false;
      api.notifyListeners();
      await t.pumpAndSettle();
      expect(
        find.text(
          'Deletion requested. Pending review; no records have been deleted.',
        ),
        findsNothing,
      );
      expect(
        find.text('The account has changed. Close this form.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('revealed key is hidden if the active account changes', (
    t,
  ) async {
    final api = AccountApi();
    await pump(t, api, const HeritageVaultView());
    await tap(t, 'Create a personal key');
    await fill(t, 'Key name *', 'My phone');
    await tap(t, 'Create key');
    expect(find.text('PRIVATE-ONCE-ONLY'), findsOneWidget);
    api.signedIn = false;
    api.notifyListeners();
    await t.pumpAndSettle();
    expect(find.text('PRIVATE-ONCE-ONLY'), findsNothing);
    expect(
      find.text('The account has changed. Close this form.'),
      findsOneWidget,
    );
    await tap(t, 'Done');
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'French account and recovery forms fit a small phone at double text size',
    (t) async {
      final api = AccountApi();
      await pump(t, api, const AccountSettingsView(), locale: 'fr', scale: 2);
      await tap(t, 'Changer le mot de passe');
      await fill(t, 'Mot de passe actuel', 'Current-834!');
      await fill(t, 'Nouveau mot de passe', 'Secure-Selection-834!');
      await fill(
        t,
        'Confirmer le nouveau mot de passe',
        'Secure-Selection-834!',
      );
      await tap(t, 'Annuler');
      expect(t.takeException(), isNull);
      await pump(t, api, const RecoveryView(), locale: 'fr', scale: 2);
      await fill(t, 'Adresse e-mail du compte', 'someone@example.test');
      await tap(t, 'Envoyer un code de récupération');
      await fill(t, 'Code reçu par e-mail', 'test-code');
      expect(t.takeException(), isNull);
    },
  );
}
