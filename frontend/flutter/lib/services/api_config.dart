import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class ApiConfig {
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      return override.replaceFirst(RegExp(r'/+$'), '');
    }

    final serverUrl = kIsWeb
        ? 'http://localhost:3000'
        : defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000'
        : 'http://127.0.0.1:3000';
    return '$serverUrl/api';
  }

  static Uri endpoint(String path) {
    final normalizedPath = path.replaceFirst(RegExp(r'^/+'), '');
    return Uri.parse('$baseUrl/$normalizedPath');
  }

  static Uri upload(String path) {
    final serverUrl = baseUrl.replaceFirst(RegExp(r'/api$'), '');
    return Uri.parse('$serverUrl$path');
  }
}
