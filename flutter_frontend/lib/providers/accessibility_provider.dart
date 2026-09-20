import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityProvider extends ChangeNotifier {
  static const String _fontScaleKey = 'accessibility_font_scale';
  static const String _seniorModeKey = 'accessibility_senior_mode';

  double _fontScale = 1.0;
  bool _isSeniorMode = false;

  double get fontScale => _fontScale;
  bool get isSeniorMode => _isSeniorMode;

  AccessibilityProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSeniorMode = prefs.getBool(_seniorModeKey) ?? false;
      _fontScale = prefs.getDouble(_fontScaleKey) ?? (_isSeniorMode ? 1.22 : 1.0);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleSeniorMode() async {
    _isSeniorMode = !_isSeniorMode;
    _fontScale = _isSeniorMode ? 1.22 : 1.0;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_seniorModeKey, _isSeniorMode);
      await prefs.setDouble(_fontScaleKey, _fontScale);
    } catch (_) {}
  }

  Future<void> setFontScale(double scale) async {
    _fontScale = scale.clamp(0.9, 1.4);
    _isSeniorMode = _fontScale > 1.1;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontScaleKey, _fontScale);
      await prefs.setBool(_seniorModeKey, _isSeniorMode);
    } catch (_) {}
  }
}
