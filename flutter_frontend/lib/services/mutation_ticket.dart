import 'dart:convert';
import 'dart:math';
import 'credential_storage.dart';

/// A pending request identity survives a crash; it never schedules a write.
class MutationTicket {
  final String identity, operation;
  MutationTicket(this.identity, this.operation);
  static String prefix(String identity) =>
      'mutation_ticket_${base64Url.encode(utf8.encode(identity))}_';
  String get _key =>
      '${prefix(identity)}${base64Url.encode(utf8.encode(operation))}';
  Future<String> begin(String body) async {
    final saved = await CredentialStorage().read(_key);
    if (saved != null) {
      try {
        final data = jsonDecode(saved) as Map;
        if (data['body'] == body) return data['key'] as String;
      } catch (_) {
        /* Replace invalid local state. */
      }
    }
    final key = List.generate(
      24,
      (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await CredentialStorage().write(
      _key,
      jsonEncode({'body': body, 'key': key}),
    );
    return key;
  }

  Future<void> finish(String key) async {
    try {
      final saved = await CredentialStorage().read(_key);
      if (saved != null && (jsonDecode(saved) as Map)['key'] == key) {
        await CredentialStorage().write(_key, null);
      }
    } catch (_) {
      /* A local receipt cleanup failure cannot undo a successful server write. */
    }
  }

  static Future<void> clearAccount(String identity) =>
      CredentialStorage().deletePrefix(prefix(identity));
}
