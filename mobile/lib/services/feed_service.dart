import 'dart:async';
import 'dart:convert';
import 'dart:io' show InternetAddress;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';
import '../core/models/feed_models.dart';

/// Service responsible for fetching today's daily pack and historical archive packs.
class FeedService {
  static final FeedService instance = FeedService._internal();
  FeedService._internal();

  /// Resolves the backend base URL
  String get _baseUrl => ApiConfig.baseUrl;

  /// Formats the client device's local calendar date as YYYY-MM-DD
  String get clientLocalDate {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Checks whether the device has a functioning internet connection outside the backend.
  Future<bool> _hasGeneralInternet() async {
    if (kIsWeb) return true;
    try {
      final lookup = await InternetAddress.lookup('dns.google').timeout(const Duration(seconds: 3));
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      try {
        final lookup = await InternetAddress.lookup('cloudflare.com').timeout(const Duration(seconds: 3));
        return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  /// Executes an HTTP GET request with retries and detailed error categorization.
  Future<FeedFetchResult> _executeRequest(Uri url) async {
    bool hasTimeout = false;
    http.Response? response;

    for (int attempt = 0; attempt <= 1; attempt++) {
      try {
        response = await http.get(url).timeout(const Duration(seconds: 12));
        break;
      } on TimeoutException {
        hasTimeout = true;
        if (attempt == 1) break;
        await Future<void>.delayed(const Duration(milliseconds: 1000));
      } catch (_) {
        if (attempt == 1) break;
        await Future<void>.delayed(const Duration(milliseconds: 1000));
      }
    }

    if (response != null && response.statusCode == 200) {
      try {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return FeedFetchResult(pack: DailyPack.fromJson(data));
      } catch (_) {
        return const FeedFetchResult(
          errorType: FeedErrorType.serverIssue,
          errorMessage: 'Malformed payload received from server',
        );
      }
    }

    if (response != null && response.statusCode >= 500) {
      return FeedFetchResult(
        errorType: FeedErrorType.serverIssue,
        errorMessage: 'Server error (${response.statusCode})',
      );
    }

    if (response != null && response.statusCode != 200) {
      return FeedFetchResult(
        errorType: FeedErrorType.serverIssue,
        errorMessage: 'Server returned HTTP ${response.statusCode}',
      );
    }

    if (hasTimeout) {
      return const FeedFetchResult(
        errorType: FeedErrorType.serverTimeout,
        errorMessage: 'Server is taking longer than usual to respond',
      );
    }

    // Connection failed: check if the device itself is offline or if only the backend is down
    final hasInternet = await _hasGeneralInternet();
    if (!hasInternet) {
      return const FeedFetchResult(
        errorType: FeedErrorType.offline,
        errorMessage: 'No active internet connection',
      );
    }

    return const FeedFetchResult(
      errorType: FeedErrorType.serverIssue,
      errorMessage: 'Cannot connect to backend server',
    );
  }

  /// Fetches today's 15-item curated feed with detailed error envelope.
  Future<FeedFetchResult> fetchTodayFeedResult({String? targetDate}) async {
    final effectiveDate = targetDate ?? clientLocalDate;
    final url = Uri.parse('$_baseUrl/api/v1/feed/today?date=$effectiveDate');
    return _executeRequest(url);
  }

  /// Fetches a historical daily pack with detailed error envelope.
  Future<FeedFetchResult> fetchArchiveFeedResult(String targetDate) async {
    final url = Uri.parse('$_baseUrl/api/v1/feed/archive?date=$targetDate');
    return _executeRequest(url);
  }

  /// Fetches today's 15-item curated feed from the FastAPI backend.
  Future<DailyPack?> fetchTodayFeed({String? targetDate}) async {
    final result = await fetchTodayFeedResult(targetDate: targetDate);
    return result.pack;
  }

  /// Fetches a historical daily pack from The Vault archive.
  Future<DailyPack?> fetchArchiveFeed(String targetDate) async {
    final result = await fetchArchiveFeedResult(targetDate);
    return result.pack;
  }
}

