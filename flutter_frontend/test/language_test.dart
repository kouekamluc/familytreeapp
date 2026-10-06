import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_frontend/l10n/app_strings.dart';
import 'package:flutter_frontend/providers/language_provider.dart';
import 'package:flutter_frontend/widgets/language_sheet.dart';
import 'package:flutter_frontend/config/royal_theme.dart';
import 'package:flutter_frontend/views/mobile/mobile_welcome_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.kkevo.family/language');
  String? native;
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    native = null; // Android before version 13.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getLanguage') return native;
          if (call.method == 'setLanguage') native = call.arguments as String;
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'English is initial; manual and system choices survive restart',
    () async {
      final language = LanguageProvider();
      await language.load();
      expect(language.locale, const Locale('en'));
      await language.setChoice('fr');
      final reopened = LanguageProvider();
      await reopened.load();
      expect(reopened.locale, const Locale('fr'));
      await reopened.setChoice('system');
      await language.load();
      expect(language.choice, 'system');
      expect(language.locale, isNull);
      language.dispose();
      reopened.dispose();
    },
  );
  test(
    'Android App languages setting overrides stale local preference',
    () async {
      SharedPreferences.setMockInitialValues({
        LanguageProvider.preferenceKey: 'en',
      });
      native = 'fr';
      final language = LanguageProvider();
      await language.load();
      expect(language.locale, const Locale('fr'));
      native = '';
      await language.load();
      expect(language.choice, 'system');
      language.dispose();
    },
  );
  test(
    'first install registers English in Android app language settings',
    () async {
      native = '';
      final language = LanguageProvider();
      await language.load();
      expect(language.locale, const Locale('en'));
      expect(native, 'en');
      language.dispose();
    },
  );
  test(
    'a delayed Android refresh cannot undo a newer language choice',
    () async {
      final requested = Completer<void>();
      final response = Completer<String>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getLanguage') {
              requested.complete();
              return response.future;
            }
            return null;
          });
      final language = LanguageProvider();
      final refresh = language.load();
      await requested.future;
      await language.setChoice('fr');
      response.complete('en');
      await refresh;
      expect(language.choice, 'fr');
      language.dispose();
    },
  );

  test('closing the provider during an Android refresh is safe', () async {
    final requested = Completer<void>();
    final response = Completer<String>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          requested.complete();
          return response.future;
        });
    final language = LanguageProvider();
    final refresh = language.load();
    await requested.future;
    language.dispose();
    response.complete('fr');
    await refresh;
  });

  test(
    'rapid selections persist the most recent language on Android',
    () async {
      final firstRequested = Completer<void>();
      final finishFirst = Completer<void>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'setLanguage') {
              if (call.arguments == 'fr') {
                firstRequested.complete();
                await finishFirst.future;
              }
              native = call.arguments as String;
            }
            return native;
          });
      final language = LanguageProvider();
      final french = language.setChoice('fr');
      await firstRequested.future;
      final english = language.setChoice('en');
      expect(language.choice, 'en');
      finishFirst.complete();
      await Future.wait([french, english]);
      expect(native, 'en');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(LanguageProvider.preferenceKey), 'en');
      await language.load();
      expect(language.choice, 'en');
      language.dispose();
    },
  );
  test(
    'relationship copy translates labels while preserving people’s names',
    () {
      const french = AppStrings(Locale('fr'));
      expect(
        french.text('Home will be the adoptive parent of Continue.'),
        'Home sera le parent adoptif de Continue.',
      );
      expect(
        french.text('Home: Adopted child of Continue.'),
        'Home : Enfant adopté de Continue.',
      );
      expect(
        french.text('Home → adoptive parent: Continue'),
        'Home → parent adoptif : Continue',
      );
      expect(french.text('1 connection'), '1 lien');
      expect(french.text('3 connections'), '3 liens');
      expect(
        french.text('{2} will be the adoptive parent of Continue.'),
        '{2} sera le parent adoptif de Continue.',
      );
    },
  );

  testWidgets('unsupported phone language falls back to English', (
    tester,
  ) async {
    tester.platformDispatcher.localeTestValue = const Locale('it');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: const [
          AppStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: MobileWelcomeView(onExplore: () {}, onSignIn: () {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Start my story'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'switching languages preserves an open form and localizes validation',
    (tester) async {
      final language = LanguageProvider();
      final controller = TextEditingController(text: 'Une histoire de famille');
      final form = GlobalKey<FormState>();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: language,
          child: Builder(
            builder: (ctx) => MaterialApp(
              theme: RoyalTheme.lightTheme,
              locale: ctx.watch<LanguageProvider>().locale,
              supportedLocales: AppStrings.supportedLocales,
              localizationsDelegates: const [
                AppStrings.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: Builder(
                builder: (context) => Scaffold(
                  body: Form(
                    key: form,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: context.tr('Their story'),
                          ),
                          validator: localizeValidator(
                            context,
                            (_) => 'This field is required.',
                          ),
                        ),
                        TextButton(
                          onPressed: () => LanguageSheet.show(context),
                          child: const AppText('Language'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Français'));
      await tester.pumpAndSettle();
      expect(find.text('Langue'), findsOneWidget);
      expect(controller.text, 'Une histoire de famille');
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration!.labelText,
        'Son histoire',
      );
      form.currentState!.validate();
      await tester.pumpAndSettle();
      expect(find.text('Ce champ est obligatoire.'), findsOneWidget);
      final reloaded = LanguageProvider();
      await reloaded.load();
      expect(reloaded.choice, 'fr');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      language.dispose();
      reloaded.dispose();
    },
  );
}
