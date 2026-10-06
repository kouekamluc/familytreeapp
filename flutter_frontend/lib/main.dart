import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_strings.dart';
import 'providers/language_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/royal_theme.dart';
import 'providers/accessibility_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/tree_provider.dart';
import 'services/api_service.dart';
import 'views/shell_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // Modern Android Edge-to-Edge display mode & transparent system bars
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  final apiService = ApiService();
  await apiService.init();

  final authProvider = AuthProvider(apiService);
  final treeProvider = TreeProvider(apiService);
  final accessibilityProvider = AccessibilityProvider();
  final languageProvider = LanguageProvider();
  await languageProvider.load();

  // Asynchronously trigger data load without blocking initial frame rendering
  treeProvider.loadData();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider.value(value: accessibilityProvider),
        ChangeNotifierProvider<ApiService>.value(value: apiService),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: treeProvider),
      ],
      child: const RoyalAncestryApp(),
    ),
  );
  apiService.probeBackend();
}

class RoyalAncestryApp extends StatelessWidget {
  const RoyalAncestryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibility = Provider.of<AccessibilityProvider>(context);

    final language = context.watch<LanguageProvider?>();
    return MaterialApp(
      locale:
          language?.locale ??
          (language?.choice == 'system' ? null : const Locale('en')),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'Kkevo Family',
      debugShowCheckedModeBanner: false,
      theme: RoyalTheme.lightTheme,
      darkTheme: RoyalTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      builder: (context, child) {
        // Respect native system text scaling multiplied by custom accessibility scale
        final systemScale = MediaQuery.textScalerOf(context).scale(1.0);
        final effectiveScale = (systemScale * accessibility.fontScale).clamp(
          0.85,
          2.2,
        );

        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: dark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(effectiveScale)),
            child: child!,
          ),
        );
      },
      home: const ShellView(),
    );
  }
}
