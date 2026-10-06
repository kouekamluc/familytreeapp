import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// English is the initial language. System is an explicit, persistent choice.
class LanguageProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const preferenceKey = 'kkevo_language';
  static const _channel = MethodChannel('com.kkevo.family/language');
  String _choice = 'en';
  int _revision = 0;
  bool _disposed = false;
  Future<void> _pendingWrite = Future<void>.value();
  String get choice => _choice;
  Locale? get locale => _choice == 'system' ? null : Locale(_choice);

  LanguageProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> load() async {
    final revision = ++_revision;
    // A lifecycle refresh must read after any in-app native update finishes.
    await _pendingWrite;
    if (_disposed || revision != _revision) return;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(preferenceKey);
    var choice = ['en', 'fr', 'system'].contains(stored) ? stored! : 'en';
    // Android 13's App languages screen is also a supported entry point.
    try {
      final native = await _channel.invokeMethod<String>('getLanguage');
      if (_disposed || revision != _revision) return;
      if (native == 'en' || native == 'fr') choice = native!;
      if (native == '' && stored != null) choice = 'system';
      if (native == '' && stored == null) {
        await _persist('en');
      }
    } on MissingPluginException {
      // Older Android and widget tests use the local preference.
    } on PlatformException {
      // Keep the persisted choice if the platform cannot provide a locale.
    }
    if (_disposed || revision != _revision) return;
    _choice = choice;
    notifyListeners();
  }

  Future<void> setChoice(String choice) async {
    if (_disposed || !['en', 'fr', 'system'].contains(choice)) return;
    ++_revision;
    _choice = choice;
    notifyListeners();
    await _persist(choice);
  }

  Future<void> _persist(String choice) {
    // Serialize writes so rapid selections finish in the same order on Android
    // and in local storage, even when a native update is slow.
    final write = _pendingWrite.then((_) => _write(choice));
    _pendingWrite = write.catchError((Object _) {});
    return write;
  }

  Future<void> _write(String choice) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(preferenceKey, choice);
    try {
      await _channel.invokeMethod<void>(
        'setLanguage',
        choice == 'system' ? '' : choice,
      );
    } on MissingPluginException {
      // Flutter handles language selection on Android versions before 13.
    } on PlatformException {
      // The in-app choice remains available without native registration.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) load();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_revision;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
