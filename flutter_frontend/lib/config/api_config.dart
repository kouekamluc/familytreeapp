import 'package:flutter/foundation.dart';
import '../services/local_storage_service.dart';

class ApiConfig {
  static String? _overrideBaseUrl;
  static const String _configuredUrl = String.fromEnvironment('API_BASE_URL');

  static Future<void> init() async {
    final saved = await LocalStorageService().getServerUrl();
    if (saved != null && saved.isNotEmpty) {
      try {
        _overrideBaseUrl = normalizeBaseUrl(saved);
      } on FormatException {
        _overrideBaseUrl = null;
      }
    }
  }

  static String normalizeBaseUrl(String url) {
    var clean = url.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(clean);
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !['', '/api'].contains(uri.path) ||
        (kReleaseMode && uri.scheme != 'https')) {
      throw const FormatException(
        'Enter a valid server address without credentials, a query or a fragment.',
      );
    }
    if (!clean.endsWith('/api')) clean = '$clean/api';
    return clean;
  }

  static Future<void> setBaseUrl(String url) async {
    final clean = normalizeBaseUrl(url);
    _overrideBaseUrl = clean;
    await LocalStorageService().saveServerUrl(clean);
  }

  static String get baseUrl {
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      return _overrideBaseUrl!;
    }
    if (_configuredUrl.isNotEmpty) return normalizeBaseUrl(_configuredUrl);

    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
      return Uri.base.scheme == 'https'
          ? '${Uri.base.origin}/api'
          : 'http://$host:8000/api';
    }

    return 'http://127.0.0.1:8000/api';
  }

  // Never send credentials to alternative hosts after a connection failure.
  static List<String> get candidateUrls => [baseUrl];

  static const String tokenEndpoint = '/auth/token/';
  static const String tokenRefreshEndpoint = '/auth/token/refresh/';
  static const String heritageKeyLoginEndpoint = '/auth/heritage-key/login/';
  static const String heritageKeysMeEndpoint = '/auth/heritage-key/me/';
  static const String heritageKeyGenerateEndpoint =
      '/auth/heritage-key/generate/';
  static const String heritageKeyRevokeEndpoint = '/auth/heritage-key/revoke/';
  static const String treesEndpoint = '/trees/';
  static const String peopleEndpoint = '/people/';
  static const String relationshipsEndpoint = '/relationships/';
  static const String mediaEndpoint = '/media/';
}
