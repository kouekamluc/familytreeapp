import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android's chooser and Storage Access Framework; no storage permissions.
class AndroidHandoff {
  static const _channel = MethodChannel('com.kkevo.family/handoff');
  static bool get available =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static Future<void> shareInvitation(String text, String title) async =>
      _channel.invokeMethod<void>('shareText', {'text': text, 'title': title});
  static Future<bool> saveJson(String json) async =>
      await _channel.invokeMethod<bool>('saveJson', {'text': json}) ?? false;
  static Future<String?> openJson() =>
      _channel.invokeMethod<String>('openJson');
}
