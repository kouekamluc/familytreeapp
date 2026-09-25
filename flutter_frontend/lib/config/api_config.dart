import 'package:flutter/foundation.dart';
import '../services/local_storage_service.dart';

class ApiConfig {
  static String? _overrideBaseUrl;
  static const String _configuredUrl = String.fromEnvironment('API_BASE_URL');

  // Common default Wi-Fi LAN endpoints for local development
  static const String currentWifiLanHost = 'http://10.172.30.60:8000/api';
  static const String fallbackWifiLanHost = 'http://192.168.1.74:8000/api';

  static Future<void> init() async {
    final saved = await LocalStorageService().getServerUrl();
    if (saved != null && saved.isNotEmpty) {
      _overrideBaseUrl = saved.endsWith('/api') ? saved : '$saved/api';
    }
  }

  static Future<void> setBaseUrl(String url) async {
    var clean = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (!clean.endsWith('/api')) {
      clean = '$clean/api';
    }
    _overrideBaseUrl = clean;
    await LocalStorageService().saveServerUrl(clean);
  }

  static String get baseUrl {
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      return _overrideBaseUrl!;
    }
    if (_configuredUrl.isNotEmpty) return _configuredUrl;

    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
      return 'http://$host:8000/api';
    }

    // Default to the PC's Wi-Fi IP so phones can connect over Wi-Fi without cable
    return currentWifiLanHost;
  }

  static List<String> get candidateUrls {
    final list = <String>[];

    // 1. User custom / saved URL has highest priority
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      list.add(_overrideBaseUrl!);
    }

    if (_configuredUrl.isNotEmpty) {
      if (!list.contains(_configuredUrl)) list.add(_configuredUrl);
    }

    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
      final webCandidate = 'http://$host:8000/api';
      if (!list.contains(webCandidate)) list.add(webCandidate);
      return list;
    }

    // 2. PC Wi-Fi addresses (for physical phone over Wi-Fi without cable)
    if (!list.contains(currentWifiLanHost)) list.add(currentWifiLanHost);
    if (!list.contains(fallbackWifiLanHost)) list.add(fallbackWifiLanHost);

    // 3. Android Emulator loopback
    if (!list.contains('http://10.0.2.2:8000/api')) list.add('http://10.0.2.2:8000/api');

    // 4. USB Cable reverse tethering (adb reverse)
    if (!list.contains('http://127.0.0.1:8000/api')) list.add('http://127.0.0.1:8000/api');

    return list;
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
