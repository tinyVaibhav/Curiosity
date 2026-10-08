import 'package:flutter/foundation.dart';
import '../../services/feed_service.dart';
import '../models/feed_models.dart';
import '../services/feed_storage_service.dart';

class FeedProvider extends ChangeNotifier {
  DailyPack? _dailyPack;
  DailyPack? _todayPack;
  bool _isLoading = false;
  bool _isSyncing = false;
  FeedErrorType _errorType = FeedErrorType.none;
  String? _errorMessage;
  bool _isViewingArchive = false;
  String? _archiveDate;

  int _syncSequence = 0;
  String _currentActiveDate = '';

  // Unread badge counters: articles: 3, quizzes: 3, cosmos: 3, facts: 6
  final Map<String, int> _unreadCounts = {
    'articles': 3,
    'quizzes': 3,
    'cosmos': 3,
    'facts': 6,
  };

  // Set of unique item identifiers already seen
  final Set<String> _seenItems = {};

  DailyPack? get dailyPack => _dailyPack;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  bool get isOffline => _errorType != FeedErrorType.none;
  FeedErrorType get errorType => _errorType;
  String? get errorMessage => _errorMessage;
  bool get isViewingArchive => _isViewingArchive;
  String? get archiveDate => _archiveDate;

  /// Descriptive user-facing message describing current sync state
  String get statusBannerMessage {
    switch (_errorType) {
      case FeedErrorType.none:
        return '';
      case FeedErrorType.offline:
        return 'No internet • Showing saved pack';
      case FeedErrorType.serverTimeout:
        return 'Server waking up… • Showing saved pack';
      case FeedErrorType.serverIssue:
        return 'Server issue • Showing saved pack';
    }
  }

  Map<String, int> get unreadCounts {
    if (_isViewingArchive) {
      // Hide bottom nav unread badges while in archive mode to isolate today's streak
      return const {'articles': 0, 'quizzes': 0, 'cosmos': 0, 'facts': 0};
    }
    return Map.unmodifiable(_unreadCounts);
  }

  Set<String> get seenItems => Set.unmodifiable(_seenItems);

  int get totalUnread => _isViewingArchive ? 0 : _unreadCounts.values.fold(0, (a, b) => a + b);

  int get completedCount => _isViewingArchive ? 15 : (15 - totalUnread).clamp(0, 15);

  FeedProvider({String? initialDate}) {
    final target = initialDate ?? FeedService.instance.clientLocalDate;
    _currentActiveDate = target;
    _initializeWithCachedData(target);
  }

  /// Phase 1: Instant local load from disk (0ms), followed by Phase 2: Background revalidation.
  void _initializeWithCachedData(String targetDate) {
    DailyPack? cached = FeedStorageService.instance.getCachedPack(targetDate);
    if (cached == null && !_isViewingArchive) {
      cached = FeedStorageService.instance.getLatestPack();
    }

    if (cached != null) {
      _dailyPack = cached;
      _seenItems.addAll(FeedStorageService.instance.getSeenItems(cached.packDate));
      _recalculateUnreadCounts();
      _isLoading = false;
    } else {
      _isLoading = true;
    }

    _syncWithServer(targetDate);
  }

  /// Phase 2: Background revalidation with race condition guard and content diffing.
  Future<void> _syncWithServer(String targetDate) async {
    final currentSeq = ++_syncSequence;
    _isSyncing = true;
    _errorType = FeedErrorType.none;
    notifyListeners();

    try {
      final result = await FeedService.instance.fetchTodayFeedResult(targetDate: targetDate);

      // Race condition guard: check if user switched date while sync was pending
      if (_syncSequence != currentSeq || _currentActiveDate != targetDate) {
        if (result.pack != null) {
          await FeedStorageService.instance.savePack(result.pack!);
        }
        return;
      }

      if (result.pack != null) {
        final pack = result.pack!;
        await FeedStorageService.instance.savePack(pack);
        if (_dailyPack == null || _hasPackChanged(_dailyPack!, pack)) {
          _dailyPack = pack;
          _seenItems.addAll(FeedStorageService.instance.getSeenItems(pack.packDate));
          _recalculateUnreadCounts();
        }
        _errorType = FeedErrorType.none;
      } else {
        // Network or server issue
        _dailyPack ??= _getBundledFallbackPack(customDate: targetDate);
        _errorType = result.errorType;
      }
    } catch (_) {
      _dailyPack ??= _getBundledFallbackPack(customDate: targetDate);
      _errorType = FeedErrorType.serverIssue;
    } finally {
      if (_syncSequence == currentSeq) {
        _isLoading = false;
        _isSyncing = false;
        _recalculateUnreadCounts();
        notifyListeners();
      }
    }
  }

  bool _hasPackChanged(DailyPack a, DailyPack b) {
    if (a.packDate != b.packDate) return true;
    if (a.articles.length != b.articles.length) return true;
    for (int i = 0; i < a.articles.length; i++) {
      if (a.articles[i].title != b.articles[i].title) return true;
    }
    return false;
  }

  /// Manually triggers a re-fetch of the active daily feed (e.g. pull-to-refresh).
  Future<void> fetchDailyFeed({String? targetDate}) async {
    final target = targetDate ?? FeedService.instance.clientLocalDate;
    _currentActiveDate = target;
    await _syncWithServer(target);
  }

  /// Loads a historical archive pack into the active shell and enters time-travel mode.
  Future<void> loadArchivePack(String targetDate) async {
    _syncSequence++;
    _currentActiveDate = targetDate;
    _isViewingArchive = true;
    _archiveDate = targetDate;

    if (_todayPack == null && _dailyPack != null) {
      _todayPack = _dailyPack;
    }

    final cached = FeedStorageService.instance.getCachedPack(targetDate);
    if (cached != null) {
      _dailyPack = cached;
      _seenItems.addAll(FeedStorageService.instance.getSeenItems(cached.packDate));
      _recalculateUnreadCounts();
      _isLoading = false;
      notifyListeners();
    } else {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final result = await FeedService.instance.fetchArchiveFeedResult(targetDate);
      if (_currentActiveDate == targetDate) {
        if (result.pack != null) {
          _dailyPack = result.pack!;
          await FeedStorageService.instance.savePack(result.pack!);
          _errorType = FeedErrorType.none;
        } else {
          _dailyPack ??= _getBundledFallbackPack(customDate: targetDate);
          _errorType = result.errorType;
        }
      }
    } catch (_) {
      if (_currentActiveDate == targetDate) {
        _dailyPack ??= _getBundledFallbackPack(customDate: targetDate);
        _errorType = FeedErrorType.serverIssue;
      }
    } finally {
      if (_currentActiveDate == targetDate) {
        _isLoading = false;
        _isSyncing = false;
        _recalculateUnreadCounts();
        notifyListeners();
      }
    }
  }

  /// Clears archive time-travel mode and restores today's live feed.
  void returnToToday() {
    _syncSequence++;
    _isViewingArchive = false;
    _archiveDate = null;
    final today = FeedService.instance.clientLocalDate;
    _currentActiveDate = today;

    if (_todayPack != null) {
      _dailyPack = _todayPack;
      _recalculateUnreadCounts();
      notifyListeners();
    } else {
      _initializeWithCachedData(today);
    }
  }

  /// Marks a specific item as read, saves to disk, and decrements category badge.
  void markItemRead(String category, String itemId) {
    if (!_seenItems.contains(itemId)) {
      _seenItems.add(itemId);
      if (_dailyPack != null) {
        FeedStorageService.instance.markItemSeen(_dailyPack!.packDate, itemId);
      }
      final current = _unreadCounts[category] ?? 0;
      if (current > 0) {
        _unreadCounts[category] = current - 1;
        notifyListeners();
      }
    }
  }

  /// Recalculates remaining unread counts
  void _recalculateUnreadCounts() {
    if (_dailyPack == null) return;

    int unreadArticles = _dailyPack!.articles
        .where((a) => !_seenItems.contains(a.title))
        .length;
    int unreadQuizzes = _dailyPack!.quizzes
        .where((q) => !_seenItems.contains(q.question))
        .length;
    int unreadCosmos = _dailyPack!.cosmos
        .where((c) => !_seenItems.contains(c.title))
        .length;
    int unreadFacts = _dailyPack!.facts
        .where((f) => !_seenItems.contains(f.text))
        .length;

    _unreadCounts['articles'] = unreadArticles;
    _unreadCounts['quizzes'] = unreadQuizzes;
    _unreadCounts['cosmos'] = unreadCosmos;
    _unreadCounts['facts'] = unreadFacts;
  }

  /// Bundled fallback payload matching the 15-item schema for offline testing.
  DailyPack _getBundledFallbackPack({String? customDate}) {
    final effectiveDate = customDate ?? FeedService.instance.clientLocalDate;
    return DailyPack(
      packDate: effectiveDate,
      articles: [
        ArticleItem(
          title: 'James_Webb_Space_Telescope',
          normalizedTitle: 'James Webb Space Telescope',
          summary:
              'The James Webb Space Telescope is an infrared space observatory conducting high-resolution observations of the earliest universe.',
          thumbnailUrl:
              'https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/James_Webb_Space_Telescope_Mirror.jpg/320px-James_Webb_Space_Telescope_Mirror.jpg',
        ),
        ArticleItem(
          title: 'Great_Barrier_Reef',
          normalizedTitle: 'Great Barrier Reef',
          summary:
              'The world\'s largest coral reef system composed of over 2,900 individual reefs stretching for over 2,300 kilometres.',
          thumbnailUrl:
              'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/GreatBarrierReef-sand-cays.jpg/320px-GreatBarrierReef-sand-cays.jpg',
        ),
        ArticleItem(
          title: 'Rosetta_(spacecraft)',
          normalizedTitle: 'Rosetta (spacecraft)',
          summary:
              'Rosetta performed a detailed study of comet 67P, performing the first successful soft landing on a comet nucleus.',
          thumbnailUrl:
              'https://upload.wikimedia.org/wikipedia/commons/thumb/9/96/Rosetta_spacecraft_model.png/320px-Rosetta_spacecraft_model.png',
        ),
      ],
      quizzes: [
        QuizItem(
          question: 'What is the powerhouse of the biological cell?',
          correctAnswer: 'Mitochondria',
          incorrectAnswers: ['Ribosome', 'Nucleus', 'Endoplasmic Reticulum'],
        ),
        QuizItem(
          question: 'Which planet has the greatest number of confirmed moons?',
          correctAnswer: 'Saturn',
          incorrectAnswers: ['Jupiter', 'Mars', 'Neptune'],
        ),
        QuizItem(
          question: 'What element does the chemical symbol Au represent?',
          correctAnswer: 'Gold',
          incorrectAnswers: ['Silver', 'Argon', 'Aluminum'],
        ),
      ],
      cosmos: [
        CosmosItem(
          title: 'The Pillars of Creation',
          explanation:
              'A celestial landscape of interstellar gas and dust located in the Eagle Nebula where active star formation occurs.',
          url: 'https://apod.nasa.gov/apod/image/2210/PillarsOfCreation_Webb_960.jpg',
        ),
        CosmosItem(
          title: 'The Andromeda Galaxy',
          explanation:
              'The nearest major spiral galaxy to the Milky Way, containing roughly one trillion stars.',
          url: 'https://apod.nasa.gov/apod/image/2108/M31_HubbleSubaruGendler_960.jpg',
        ),
        CosmosItem(
          title: 'The Pale Blue Dot',
          explanation:
              'A photograph of Earth captured from 6 billion kilometers by Voyager 1.',
          url: 'https://apod.nasa.gov/apod/image/2002/PaleBlueDot_Voyager1_960.jpg',
        ),
      ],
      facts: [
        FactItem(
          text: 'Honey never spoils; 3,000-year-old honey excavated from Egyptian tombs is still edible.',
          source: 'Useless Facts',
        ),
        FactItem(
          text: 'Octopuses possess three hearts and circulate hemocyanin-rich blue blood.',
          source: 'Useless Facts',
        ),
        FactItem(
          text: '42 is the precise angle in degrees at which light reflects to form a rainbow.',
          source: 'Numbers API',
        ),
        FactItem(
          text: '73 is the 21st prime number; its mirror 37 is the 12th prime number.',
          source: 'Numbers API',
        ),
        FactItem(
          text: 'In 1969: Apollo 11 touched down on the lunar surface.',
          source: 'Wikipedia (On This Day)',
        ),
        FactItem(
          text: 'In 1928: Sir Alexander Fleming discovered penicillin.',
          source: 'Wikipedia (On This Day)',
        ),
      ],
    );
  }
}
