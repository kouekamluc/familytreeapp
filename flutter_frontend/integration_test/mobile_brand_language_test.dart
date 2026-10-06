import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/main.dart' as app;
import 'package:flutter_frontend/providers/language_provider.dart';
import 'package:flutter_frontend/services/api_service.dart';
import 'package:flutter_frontend/views/mobile/mobile_welcome_view.dart';
import 'package:flutter_frontend/widgets/language_sheet.dart';
import 'package:flutter_frontend/widgets/kkevo_brand.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android branding, English-first, French and phone-default language',
    (tester) async {
      final api = ApiService();
      await api.init();
      await api.logout();
      await app.main();
      await tester.pumpAndSettle();
      final language = tester
          .element(find.byType(MobileWelcomeView))
          .read<LanguageProvider>();
      await language.setChoice('en');
      await tester.pumpAndSettle();
      expect(find.byType(KkevoBrand), findsOneWidget);
      expect(find.text('Start my story'), findsOneWidget);
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('mobile-eban-welcome-en');

      await tester.tap(find.byTooltip('Language'));
      await tester.pumpAndSettle();
      expect(find.byType(LanguageSheet), findsOneWidget);
      await tester.tap(find.text('Français'));
      await tester.pumpAndSettle();
      expect(find.text('Commencer mon histoire'), findsOneWidget);
      expect(find.byTooltip('Langue'), findsOneWidget);
      await binding.takeScreenshot('mobile-eban-welcome-fr');

      final reopened = LanguageProvider();
      await reopened.load();
      expect(reopened.choice, 'fr');
      reopened.dispose();
      await tester.tap(find.byTooltip('Langue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Utiliser la langue du téléphone'));
      await tester.pumpAndSettle();
      expect(language.choice, 'system');
      final phoneFrench = tester.platformDispatcher.locale.languageCode == 'fr';
      expect(
        find.text(phoneFrench ? 'Commencer mon histoire' : 'Start my story'),
        findsOneWidget,
      );

      await language.setChoice('en');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Explore an example family'));
      for (
        var i = 0;
        i < 80 &&
            find.text('Example family · fictional records').evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      await tester.pumpAndSettle();
      expect(find.text('Example family · fictional records'), findsOneWidget);
      expect(find.text('Your family at a glance'), findsOneWidget);
      await binding.takeScreenshot('mobile-eban-home-en');
      await tester.tap(find.text('You'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Language').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Language').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Français'));
      await tester.pumpAndSettle();
      expect(find.text('Langue'), findsOneWidget);
      await tester.tap(find.text('Accueil'));
      await tester.pumpAndSettle();
      expect(find.text('Votre famille en un regard'), findsOneWidget);
      await binding.takeScreenshot('mobile-eban-home-fr');
      await language.setChoice('en');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      debugPrint(
        'MOBILE BRAND AND LANGUAGE JOURNEY PASSED: Eban, English/French, persisted choice, native/system choice, welcome and account language entry points.',
      );
    },
  );
}
