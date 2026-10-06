import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_frontend/main.dart';
import 'package:flutter_frontend/providers/auth_provider.dart';
import 'package:flutter_frontend/providers/tree_provider.dart';
import 'package:flutter_frontend/providers/theme_provider.dart';
import 'package:flutter_frontend/providers/accessibility_provider.dart';
import 'package:flutter_frontend/services/api_service.dart';
import 'package:flutter_frontend/views/auth/account_settings_view.dart';
import 'package:flutter_frontend/views/mobile/mobile_welcome_view.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android account details, one-time key, deletion review and password change',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final api = ApiService();
      await api.init();
      await api.logout();
      final username = 'account_${DateTime.now().millisecondsSinceEpoch}';
      const password = 'Initial-Puzzle-482!';
      const newPassword = 'Forest-Rhythm-837!';
      expect(
        await api.register(
          username: username,
          email: '$username@example.test',
          password: password,
          firstName: 'Mobile',
          lastName: 'Tester',
        ),
        isTrue,
        reason: api.lastError,
      );
      final auth = AuthProvider(api), tree = TreeProvider(api);
      await tree.loadData();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ApiService>.value(value: api),
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider.value(value: tree),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
          ],
          child: const RoyalAncestryApp(),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> wait(bool Function() ready) async {
        for (var i = 0; i < 100 && !ready(); i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(ready(), isTrue, reason: api.lastError);
        await tester.pumpAndSettle();
      }

      Future<void> tap(String label) async {
        final f = find.text(label).last;
        await wait(() => f.evaluate().isNotEmpty);
        await tester.ensureVisible(f);
        await tester.pumpAndSettle();
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      Future<void> fill(String label, String value) async {
        final f = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == label,
        );
        await wait(() => f.evaluate().isNotEmpty);
        await tester.ensureVisible(f);
        await tester.pumpAndSettle();
        await tester.tap(f);
        await tester.pumpAndSettle();
        await tester.enterText(f, value);
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(f).controller?.text == value,
          isTrue,
          reason: 'Native input did not retain the entered value for $label',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(f).controller?.text == value,
          isTrue,
          reason: 'Native input changed while closing the keyboard for $label',
        );
      }

      await tap('You');
      await tap('My personal keys');
      await tap('Create a personal key');
      await fill('Key name *', 'Audit phone');
      await tap('Create key');
      await wait(
        () => find.text('Save your personal key').evaluate().isNotEmpty,
      );
      expect(auth.heritageKeys.single.key, startsWith('Hidden personal key #'));
      await tap('Done');
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Audit phone'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tap('Account and security');
      await wait(() => find.text('Edit account details').evaluate().isNotEmpty);
      await tap('Edit account details');
      await fill('First name', 'Updated');
      await fill('Last name', 'Tester');
      await fill('Current password', password);
      await tap('Save account details');
      await wait(() => find.text('Updated Tester').evaluate().isNotEmpty);

      await tap('Request account deletion');
      await fill('Current password', 'wrong');
      await tap('Request account deletion');
      await wait(
        () => find
            .text('Your current password is incorrect.')
            .evaluate()
            .isNotEmpty,
      );
      await fill('Current password', password);
      await tap('Request account deletion');
      await wait(
        () => find
            .text(
              'Deletion requested. Pending review; no records have been deleted.',
            )
            .evaluate()
            .isNotEmpty,
      );
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('mobile-account-deletion-pending');
      await tap('Cancel deletion request');
      await fill('Current password', password);
      await tap('Cancel deletion request');
      await wait(
        () => find.text('Request account deletion').evaluate().isNotEmpty,
      );
      expect((await api.accountDetails())?['deletion_status'], 'CANCELLED');
      await tap('Change password');
      await fill('Current password', password);
      await fill('New password', newPassword);
      await fill('Confirm new password', newPassword);
      await tap('Change password');
      await wait(
        () =>
            !api.isAuthenticated &&
            find.byType(AccountSettingsView).evaluate().isEmpty,
      );
      expect(find.byType(MobileWelcomeView), findsOneWidget);
      expect(await api.login(username, password), isFalse);
      expect(
        await api.login(username, newPassword),
        isTrue,
        reason: api.lastError,
      );
      expect((await api.accountDetails())?['user']['first_name'], 'Updated');
      await api.logout();
      expect(tester.takeException(), isNull);
      debugPrint(
        'ANDROID ACCOUNT JOURNEY PASSED: details, hidden key, rejected password, request/cancel, password change and fresh sign-in.',
      );
    },
  );
}
