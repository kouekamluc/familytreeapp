import 'package:flutter/foundation.dart';

class ApiConfig {
  static String? _overrideBaseUrl;

  static void setBaseUrl(String url) {
    _overrideBaseUrl = url;
  }

  static String get baseUrl {
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      return _overrideBaseUrl!;
    }
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
      return 'http://$host:8000/api';
    }
    // Host PC LAN IP works directly over Wi-Fi & USB on physical mobile device:
    return 'http://192.168.1.74:8000/api';
  }

  static List<String> get candidateUrls {
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
      return ['http://$host:8000/api'];
    }
    return [
      'http://127.0.0.1:8000/api',
      'http://192.168.1.74:8000/api',
      'http://10.0.2.2:8000/api',
    ];
  }

  static const String tokenEndpoint = '/auth/token/';
  static const String tokenRefreshEndpoint = '/auth/token/refresh/';
  static const String heritageKeyLoginEndpoint = '/auth/heritage-key/login/';
  static const String heritageKeysMeEndpoint = '/auth/heritage-key/me/';
  static const String heritageKeyGenerateEndpoint = '/auth/heritage-key/generate/';
  static const String heritageKeyRevokeEndpoint = '/auth/heritage-key/revoke/';
  static const String treesEndpoint = '/trees/';
  static const String peopleEndpoint = '/people/';
  static const String relationshipsEndpoint = '/relationships/';
  static const String mediaEndpoint = '/media/';
}
