import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/feed_models.dart';

/// Service responsible for local disk persistence of daily packs and user read progress
/// utilizing SharedPreferences as an in-memory cached key-value store.
class FeedStorageService {
  static final FeedStorageService instance = FeedStorageService._internal();
  FeedStorageService._internal();

  SharedPreferences? _prefs;

  /// Injects the pre-warmed SharedPreferences instance (typically initialized in main.dart).
  void initialize(SharedPreferences prefs) {
    _prefs = prefs;
  }

  /// Whether the storage service is initialized.
  bool get isInitialized => _prefs != null;

  /// Retrieves the cached [DailyPack] for a given [date] (YYYY-MM-DD).
  /// Synchronous and fast (0ms) because SharedPreferences caches all keys in RAM.
  /// Includes crash-proof error recovery against corrupted writes or schema evolutions.
  DailyPack? getCachedPack(String date) {
    if (_prefs == null) return null;
    final raw = _prefs!.getString('feed_pack_$date');
    if (raw == null || raw.isEmpty) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return DailyPack.fromJson(map);
    } catch (e) {
      // Corrupted JSON or schema mismatch: defensively wipe the key to avoid crashes
      debugPrint('[FeedStorageService] Corrupted cache for $date wiped: $e');
      _prefs!.remove('feed_pack_$date');
      return null;
    }
  }

  /// Retrieves the most recent pack saved to disk regardless of calendar date.
  /// Used for immediate rendering on cold start before network revalidation.
  DailyPack? getLatestPack() {
    if (_prefs == null) return null;
    final latestDate = _prefs!.getString('feed_latest_date');
    if (latestDate != null && latestDate.isNotEmpty) {
      final pack = getCachedPack(latestDate);
      if (pack != null) return pack;
    }
    return null;
  }

  /// Persists a [DailyPack] to disk asynchronously without blocking the UI thread.
  Future<void> savePack(DailyPack pack) async {
    if (_prefs == null) return;
    try {
      final raw = jsonEncode(pack.toJson());
      await _prefs!.setString('feed_pack_${pack.packDate}', raw);

      final currentLatest = _prefs!.getString('feed_latest_date') ?? '';
      if (pack.packDate.compareTo(currentLatest) >= 0) {
        await _prefs!.setString('feed_latest_date', pack.packDate);
      }

      // Automatically prune ancient packs in background
      unawaited(pruneOldPacks());
    } catch (e) {
      debugPrint('[FeedStorageService] Failed to save pack ${pack.packDate}: $e');
    }
  }

  /// Retrieves the set of seen item IDs for a specific date.
  Set<String> getSeenItems(String date) {
    if (_prefs == null) return {};
    final list = _prefs!.getStringList('feed_seen_$date');
    return list != null ? list.toSet() : {};
  }

  /// Persists an item ID as seen for a specific date.
  Future<void> markItemSeen(String date, String itemId) async {
    if (_prefs == null) return;
    try {
      final key = 'feed_seen_$date';
      final current = _prefs!.getStringList(key) ?? [];
      if (!current.contains(itemId)) {
        current.add(itemId);
        await _prefs!.setStringList(key, current);
      }
    } catch (e) {
      debugPrint('[FeedStorageService] Failed to persist seen item $itemId: $e');
    }
  }

  /// Prunes cached packs older than [keepDays] to prevent unbounded storage growth.
  Future<void> pruneOldPacks({int keepDays = 14}) async {
    if (_prefs == null) return;
    try {
      final cutoff = DateTime.now().subtract(Duration(days: keepDays));
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        if (key.startsWith('feed_pack_')) {
          final dateStr = key.replaceFirst('feed_pack_', '');
          final parsedDate = DateTime.tryParse(dateStr);
          if (parsedDate != null && parsedDate.isBefore(cutoff)) {
            await _prefs!.remove(key);
            await _prefs!.remove('feed_seen_$dateStr');
          }
        }
      }
    } catch (e) {
      debugPrint('[FeedStorageService] Pruning error: $e');
    }
  }

  /// Helper for unawaited background tasks
  static void unawaited(Future<void> future) {
    future.catchError((_) {});
  }
}
