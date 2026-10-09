import 'package:flutter/foundation.dart';
import '../constants/api_config.dart';

/// Utilities for resolving and optimizing image URLs across web and native platforms.
class ImageUtils {
  /// Resolves the backend base URL depending on runtime platform.
  static String get baseUrl => ApiConfig.baseUrl;

  /// Resolves an image URL so it renders properly across all platforms.
  ///
  /// On Web (CanvasKit/WebGL), the browser strictly enforces CORS for image bytes.
  /// External services like NASA APOD (apod.nasa.gov) do not send CORS headers,
  /// causing Image.network to fail. Routing through the backend proxy ensures
  /// proper Access-Control-Allow-Origin headers, fast caching, and reliable rendering.
  static String resolveImageUrl(String? url, {bool forceProxy = false}) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();

    // Data URIs are self-contained
    if (trimmed.startsWith('data:')) {
      return trimmed;
    }

    // If already contains a proxy path, re-anchor to current platform baseUrl
    if (trimmed.contains('/api/v1/feed/proxy-image?url=')) {
      final rawParam = trimmed.split('/api/v1/feed/proxy-image?url=').last;
      return '$baseUrl/api/v1/feed/proxy-image?url=$rawParam';
    }

    // Remap broken/deprecated apod.nasa.gov endpoints to permanent high-res CDNs
    String effectiveUrl = trimmed;
    if (trimmed == 'https://apod.nasa.gov/apod/image/2210/PillarsOfCreation_Webb_960.jpg') {
      effectiveUrl = 'https://upload.wikimedia.org/wikipedia/commons/b/b2/Eagle_nebula_pillars.jpg';
    } else if (trimmed == 'https://apod.nasa.gov/apod/image/2108/M31_HubbleSubaruGendler_960.jpg') {
      effectiveUrl = 'https://images-assets.nasa.gov/image/PIA23645/PIA23645~orig.jpg';
    } else if (trimmed == 'https://apod.nasa.gov/apod/image/2002/PaleBlueDot_Voyager1_960.jpg') {
      effectiveUrl = 'https://upload.wikimedia.org/wikipedia/commons/7/73/Pale_Blue_Dot.png';
    }

    // On Web, proxy external images to guarantee CORS compliance
    if (kIsWeb || forceProxy) {
      return '$baseUrl/api/v1/feed/proxy-image?url=${Uri.encodeComponent(effectiveUrl)}';
    }

    return effectiveUrl;
  }

  /// Upgrades a Wikimedia thumbnail URL to a higher resolution (e.g. 640px)
  /// when applicable, for crisp display on high-density Retina screens.
  static String upgradeWikiThumbnail(String? url, {int targetWidth = 640}) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    final regExp = RegExp(r'/(\d+)px-([^/]+)$');
    if (regExp.hasMatch(trimmed)) {
      return trimmed.replaceFirstMapped(regExp, (match) {
        final currentWidth = int.tryParse(match.group(1) ?? '320') ?? 320;
        if (currentWidth < targetWidth) {
          return '/${targetWidth}px-${match.group(2)}';
        }
        return match.group(0)!;
      });
    }
    return trimmed;
  }
}
