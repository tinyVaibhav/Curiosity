import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/models/feed_models.dart';

/// Service responsible for fetching today's daily pack and historical archive packs.
class FeedService {
  static final FeedService instance = FeedService._internal();
  FeedService._internal();

  /// Resolves the backend base URL depending on platform
  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch (_) {}
    return 'http://localhost:8000';
  }

  /// Fetches today's 15-item curated feed from the FastAPI backend.
  /// Accepts an optional [targetDate] in 'YYYY-MM-DD' format.
  Future<DailyPack?> fetchTodayFeed({String? targetDate}) async {
    final query = targetDate != null ? '?date=$targetDate' : '';
    final url = Uri.parse('$_baseUrl/api/v1/feed/today$query');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return DailyPack.fromJson(data);
      }
    } catch (_) {
      // Handled by caller to switch to offline bundled fallback
    }
    return null;
  }

  /// Fetches a historical daily pack from The Vault archive.
  Future<DailyPack?> fetchArchiveFeed(String targetDate) async {
    final url = Uri.parse('$_baseUrl/api/v1/feed/archive?date=$targetDate');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return DailyPack.fromJson(data);
      }
    } catch (_) {
      // Handled by caller
    }
    return null;
  }
}
