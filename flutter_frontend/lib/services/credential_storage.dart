import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Credentials use the platform vault. Older preferences migrate on first read.
class CredentialStorage {
  static const _vault = FlutterSecureStorage();
  static Future<void>? _pendingWrites;
  static Future<void> _enqueue(Future<void> Function() action) {
    final previous = _pendingWrites;
    final operation = Future<void>.sync(() async {
      if (previous != null) await previous.catchError((Object _) {});
      await action();
    });
    _pendingWrites = operation;
    void release() {
      if (identical(_pendingWrites, operation)) _pendingWrites = null;
    }

    operation.then(
      (_) => release(),
      onError: (Object _, StackTrace __) => release(),
    );
    return operation;
  }

  Future<String?> read(String key) async {
    final pending = _pendingWrites;
    if (pending != null) await pending.catchError((Object _) {});
    final protected = await _vault.read(key: key);
    if (protected != null) return protected;
    final prefs = await SharedPreferences.getInstance();
    final previous = prefs.getString(key);
    if (previous != null) {
      await write(key, previous);
    }
    return previous;
  }

  Future<void> write(String key, String? value) =>
      _enqueue(() => _write(key, value));

  Future<void> _write(String key, String? value) async {
    if (value == null) {
      await _vault.delete(key: key);
    } else {
      await _vault.write(key: key, value: value);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  Future<void> deletePrefix(String prefix) => _enqueue(() async {
    final prefs = await SharedPreferences.getInstance();
    final protected = await _vault.readAll();
    for (final key in {
      ...protected.keys,
      ...prefs.getKeys(),
    }.where((k) => k.startsWith(prefix))) {
      await _vault.delete(key: key);
      await prefs.remove(key);
    }
  });
}
