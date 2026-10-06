import 'dart:async';
import 'dart:convert';
import 'credential_storage.dart';

/// Expiring, device-only drafts. Scope includes the server and signed-in account.
class EditDrafts {
  static const lifetime = Duration(hours: 24);
  static String prefix(String identity) =>
      'edit_draft_${base64Url.encode(utf8.encode(identity))}_';
  static Future<void> clearAccount(String identity) =>
      CredentialStorage().deletePrefix(prefix(identity));
  final String identity, record;
  EditDrafts(this.identity, this.record);
  String get _key =>
      '${prefix(identity)}${base64Url.encode(utf8.encode(record))}';
  Future<Map<String, dynamic>?> read() async {
    try {
      final encoded = await CredentialStorage().read(_key);
      if (encoded == null) return null;
      final data = jsonDecode(encoded) as Map<String, dynamic>;
      final time = DateTime.parse(data['saved_at'] as String);
      final age = DateTime.now().toUtc().difference(time);
      if (age.isNegative || age > lifetime) {
        await clear();
        return null;
      }
      return data['draft'] as Map<String, dynamic>;
    } catch (_) {
      try {
        await clear();
      } catch (_) {
        /* Unavailable device storage. */
      }
      return null;
    }
  }

  Future<void> write(Map<String, dynamic> draft) => CredentialStorage().write(
    _key,
    jsonEncode({
      'saved_at': DateTime.now().toUtc().toIso8601String(),
      'draft': draft,
    }),
  );
  Future<void> clear() => CredentialStorage().write(_key, null);
}

class EditDraftSession {
  final EditDrafts storage;
  final bool Function() active;
  final Map<String, dynamic> Function() snapshot;
  Timer? _timer;
  bool _closed = false;
  String? _observed;
  EditDraftSession(this.storage, this.active, this.snapshot);

  /// Observe a form rebuild without repeatedly writing unchanged choices.
  void observe(bool dirty) {
    final signature = jsonEncode(snapshot());
    if (_observed == signature) return;
    final initialBuild = _observed == null;
    _observed = signature;
    if (initialBuild && !dirty) return; // Leave any restorable draft intact.
    if (dirty) {
      changed();
    } else {
      reset();
    }
  }

  void changed() {
    _timer?.cancel();
    if (_closed || !active()) return;
    final data = snapshot();
    _timer = Timer(const Duration(milliseconds: 350), () async {
      if (_closed || !active()) return;
      try {
        await storage.write(data);
      } catch (_) {
        /* Editing and saving remain available. */
      }
    });
  }

  Future<void> finish() async {
    _closed = true;
    _timer?.cancel();
    try {
      await storage.clear();
    } catch (_) {
      /* Never block exit on a device storage failure. */
    }
  }

  void reset() {
    _timer?.cancel();
    storage.clear().catchError((Object _) {});
  }

  void flush() {
    _timer?.cancel();
    if (!_closed && active()) {
      storage.write(snapshot()).catchError((Object _) {});
    }
  }

  void dispose() {
    _closed = true;
    _timer?.cancel();
  }
}
