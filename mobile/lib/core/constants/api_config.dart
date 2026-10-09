import 'package:flutter/foundation.dart';

/// Centralized configuration for the backend API base URL.
///
/// Supports:
/// 1. Runtime override via [setCustomUrl]
/// 2. Compile-time `--dart-define=API_URL=https://your-backend.onrender.com`
/// 3. Web dynamic host resolution
/// 4. Physical device default (LAN IP: 192.168.0.102) / fallback localhost
class ApiConfig {
  static const String defaultProductionUrl = 'https://curiosity-backend-90rd.onrender.com';
  static const String _envUrl = String.fromEnvironment('API_URL');
  static String? _customUrl;

  /// Allows setting a custom backend URL at runtime (e.g. from app settings).
  static void setCustomUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      _customUrl = null;
    } else {
      _customUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    }
  }

  /// Gets the currently active API base URL without any trailing slash.
  static String get baseUrl {
    if (_customUrl != null && _customUrl!.isNotEmpty) {
      return _customUrl!;
    }

    if (_envUrl.isNotEmpty) {
      return _envUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }

    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.host.isNotEmpty && uri.host != 'localhost' && uri.host != '127.0.0.1') {
        return '${uri.scheme}://${uri.host}:8000';
      }
      return defaultProductionUrl;
    }

    return defaultProductionUrl;
  }
}
