import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/royal_theme.dart';
import 'providers/accessibility_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/tree_provider.dart';
import 'services/api_service.dart';
import 'views/shell_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  // Lock orientation to portrait modes on mobile phones to prevent layout breakage
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final apiService = ApiService();
  await apiService.init();

  final authProvider = AuthProvider(apiService);
  final treeProvider = TreeProvider(apiService);
  final accessibilityProvider = AccessibilityProvider();

  // Unconditionally preload dynasty lineage records so people and tree are always available
  await treeProvider.loadData();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: accessibilityProvider),
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: treeProvider),
      ],
      child: const RoyalAncestryApp(),
    ),
  );
}

class RoyalAncestryApp extends StatelessWidget {
  const RoyalAncestryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibility = Provider.of<AccessibilityProvider>(context);

    return MaterialApp(
      title: 'Royal Ancestry - African Dynasty Tree',
      debugShowCheckedModeBanner: false,
      theme: RoyalTheme.lightTheme,
      darkTheme: RoyalTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(accessibility.fontScale),
          ),
          child: child!,
        );
      },
      home: const ShellView(),
    );
  }
}
