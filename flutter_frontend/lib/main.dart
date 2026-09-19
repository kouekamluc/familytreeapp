import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/royal_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/tree_provider.dart';
import 'services/api_service.dart';
import 'views/shell_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = ApiService();
  await apiService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService)),
        ChangeNotifierProvider(create: (_) => TreeProvider(apiService)..loadData()),
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

    return MaterialApp(
      title: 'Royal Ancestry - African Dynasty Tree',
      debugShowCheckedModeBanner: false,
      theme: RoyalTheme.lightTheme,
      darkTheme: RoyalTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const ShellView(),
    );
  }
}
