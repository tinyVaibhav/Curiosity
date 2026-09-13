import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Utilities for resolving and optimizing image URLs across web and native platforms.
class ImageUtils {
  /// Resolves the backend base URL depending on runtime platform.
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch (_) {}
    return 'http://localhost:8000';
  }

  /// Resolves an image URL so it renders properly across all platforms.
  ///
  /// On Web (CanvasKit/WebGL), the browser strictly enforces CORS for image bytes.
  /// External services like NASA APOD (apod.nasa.gov) do not send CORS headers,
  /// causing Image.network to fail. Routing through the backend proxy ensures
  /// proper Access-Control-Allow-Origin headers, fast caching, and reliable rendering.
  static String resolveImageUrl(String? url, {bool forceProxy = false}) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();

    // Already proxied or data URI
    if (trimmed.startsWith(baseUrl) || trimmed.startsWith('data:')) {
      return trimmed;
    }

    // On Web, proxy external images to guarantee CORS compliance
    if (kIsWeb || forceProxy) {
      return '$baseUrl/api/v1/feed/proxy-image?url=${Uri.encodeComponent(trimmed)}';
    }

    return trimmed;
  }
}
