import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000/api';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return 'http://127.0.0.1:8000/api';
    }
  }

  static const String tokenEndpoint = '/auth/token/';
  static const String tokenRefreshEndpoint = '/auth/token/refresh/';
  static const String treesEndpoint = '/trees/';
  static const String peopleEndpoint = '/people/';
  static const String relationshipsEndpoint = '/relationships/';
  static const String mediaEndpoint = '/media/';
}
