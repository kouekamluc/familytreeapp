import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themePrefKey = 'royal_theme_is_dark';
  bool _isDark = true;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_themePrefKey)) {
        _isDark = prefs.getBool(_themePrefKey) ?? true;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themePrefKey, _isDark);
    } catch (_) {}
  }
}
