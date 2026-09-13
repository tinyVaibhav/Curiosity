import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:curiosity_mobile/core/state/feed_provider.dart';
import 'package:curiosity_mobile/core/utils/text_utils.dart';
import 'package:curiosity_mobile/main.dart';
import 'package:curiosity_mobile/widgets/vault_history_card.dart';

void main() {
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  group('TextUtils Unit Tests', () {
    test('cleanWikiTitle cleans underscores and strips disambiguation suffixes', () {
      expect(TextUtils.cleanWikiTitle('Music_Box_(album)'), 'Music Box');
      expect(TextUtils.cleanWikiTitle('James_Webb_Space_Telescope'), 'James Webb Space Telescope');
      expect(TextUtils.cleanWikiTitle('Mercury_(planet)'), 'Mercury');
      expect(TextUtils.cleanWikiTitle('Apollo_11'), 'Apollo 11');
    });

    test('formatWikipediaUrl returns canonical mobile URL', () {
      expect(
        TextUtils.formatWikipediaUrl('James Webb Space Telescope'),
        'https://en.m.wikipedia.org/wiki/James_Webb_Space_Telescope',
      );
    });
  });

  group('All 4 Feed Screens Integration Tests', () {
    testWidgets('Articles, Cosmos, Quizzes, and Facts interactive flows', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const CuriosityApp());
      await tester.pumpAndSettle();

      // --- 1. ARTICLES TAB (Tab 0) ---
      expect(find.text('DAILY DEEP DIVES'), findsOneWidget);
      expect(find.text('Read Full Article ↗'), findsWidgets);

      // Tap first article card to open reader modal
      await tester.tap(find.text('Read Full Article ↗').first);
      await tester.pumpAndSettle();
      expect(find.text('Open Full Wikipedia Article ↗'), findsOneWidget);

      // Close modal
      Navigator.of(tester.element(find.text('Open Full Wikipedia Article ↗'))).pop();
      await tester.pumpAndSettle();

      // Verify article badge decremented: 2 unread
      expect(find.text('2 unread'), findsOneWidget);

      // --- 2. QUIZZES TAB (Tab 1) ---
      await tester.tap(find.text('Quizzes'));
      await tester.pumpAndSettle();

      expect(find.text('DAILY TRIVIA QUIZZES'), findsOneWidget);
      expect(find.text('#QUIZ'), findsWidgets);

      // Tap an answer option on the first question
      final optionFinder = find.byType(InkWell);
      await tester.tap(optionFinder.first);
      await tester.pumpAndSettle();

      // Verify explanation box appears with answer feedback
      expect(find.textContaining('answer is', findRichText: true), findsWidgets);
      expect(find.text('Answered'), findsWidgets);

      // --- 3. COSMOS TAB (Tab 2) ---
      await tester.tap(find.text('Cosmos'));
      await tester.pumpAndSettle();

      expect(find.text('ASTRONOMY & COSMOS'), findsOneWidget);
      expect(find.text('Read Scientific Breakdown'), findsWidgets);

      // Tap accordion trigger to expand scientific breakdown
      await tester.tap(find.text('Read Scientific Breakdown').first);
      await tester.pumpAndSettle();

      expect(find.text('Collapse Scientific Breakdown'), findsOneWidget);

      // --- 4. FACTS TAB (Tab 3) ---
      await tester.tap(find.text('Facts'));
      await tester.pumpAndSettle();

      expect(find.text('DAILY COMPOSITE FACTS'), findsOneWidget);
      expect(find.text('Bookmark'), findsWidgets);
      expect(find.text('Share'), findsWidgets);

      // Test Bookmark toggle
      await tester.tap(find.text('Bookmark').first);
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsOneWidget);

      // Verify FeedProvider state directly: mark fact read
      final feedProvider = Provider.of<FeedProvider>(
        tester.element(find.text('DAILY COMPOSITE FACTS')),
        listen: false,
      );
      // Advance virtual clock past the 1-second dwell threshold for visible FactCards
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();

      // Visibility dwell timer fired for visible cards on screen
      expect(feedProvider.unreadCounts['facts'], lessThan(6));
      expect(find.textContaining('unread'), findsWidgets);

      // Drain any pending micro-timers before teardown
      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('Command Palette and Discovery Tests', () {
    testWidgets('Opens Command Palette, runs debounced search, surfaces surprise items and category feed', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const CuriosityApp());
      await tester.pumpAndSettle();

      // 1. Trigger Command Palette from TopBar
      expect(find.text('Search topics…'), findsOneWidget);
      expect(find.text('⌘\u00A0K'), findsOneWidget);

      await tester.tap(find.text('Search topics…'));
      await tester.pumpAndSettle();

      // 2. Initial state: Serendipity and Categories
      expect(find.text('SERENDIPITY'), findsOneWidget);
      expect(find.text('Surprise Article'), findsOneWidget);
      expect(find.text('Surprise Fact'), findsOneWidget);
      expect(find.text('EXPLORE TOPICS'), findsOneWidget);
      expect(find.text('🚀 Space & Physics'), findsOneWidget);
      expect(find.text('🏛️ Ancient History'), findsOneWidget);
      expect(find.text('🧬 Biology & Nature'), findsOneWidget);
      expect(find.text('💻 Tech & Logic'), findsOneWidget);

      // 3. Test Surprise Fact trigger
      await tester.tap(find.text('Surprise Fact'));
      await tester.pumpAndSettle();

      expect(find.textContaining('#SURPRISE FACT'), findsOneWidget);
      expect(find.text('Roll Another Fact'), findsOneWidget);

      // Close fact modal
      Navigator.of(tester.element(find.text('Roll Another Fact'))).pop();
      await tester.pumpAndSettle();

      // Re-open palette
      await tester.tap(find.text('Search topics…'));
      await tester.pumpAndSettle();

      // 4. Test live search with debounce
      await tester.enterText(find.byType(TextField), 'Webb');
      // Advance debounce timer (300ms)
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Results rendered
      expect(find.text('James Webb Space Telescope'), findsWidgets);

      // Tap search result -> opens ArticleReaderModal
      await tester.tap(find.text('James Webb Space Telescope').last);
      await tester.pumpAndSettle();

      expect(find.text('Open Full Wikipedia Article ↗'), findsOneWidget);

      // Close reader modal
      Navigator.of(tester.element(find.text('Open Full Wikipedia Article ↗'))).pop();
      await tester.pumpAndSettle();

      // Re-open palette
      await tester.tap(find.text('Search topics…'));
      await tester.pumpAndSettle();

      // 5. Test Category Feed navigation
      await tester.tap(find.text('🚀 Space & Physics'));
      await tester.pumpAndSettle();

      // In CategoryFeedScreen
      expect(find.text('Back to Today'), findsOneWidget);
      expect(find.text('🚀 Space & Physics'), findsOneWidget);

      // Scroll to reveal the Load More button at the bottom of the card deck
      await tester.scrollUntilVisible(
        find.textContaining('Load More'),
        500.0,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.textContaining('Load More'), findsOneWidget);

      // Test Back to Today
      await tester.tap(find.text('Back to Today'));
      await tester.pumpAndSettle();

      expect(find.text('DAILY DEEP DIVES'), findsOneWidget);
    });
  });

  group('The Vault and Time Travel UX Tests', () {
    testWidgets('Opens The Vault, renders 30-day timeline, initiates time travel, and returns to today', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const CuriosityApp());
      await tester.pumpAndSettle();

      // 1. Open The Vault via calendar button in top bar
      final vaultButton = find.byTooltip('The Vault, view archives');
      expect(vaultButton, findsOneWidget);

      await tester.tap(vaultButton);
      await tester.pumpAndSettle();

      // 2. Verify The Vault screen
      expect(find.text('The Vault (Past 30 Days)'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      // Verify history cards rendered
      expect(find.byType(VaultHistoryCard), findsWidgets);

      // 3. Tap first history card to trigger time travel
      await tester.tap(find.byType(VaultHistoryCard).first);
      await tester.pumpAndSettle();

      // 4. Returned to MainShellScreen with archive banner active
      expect(find.textContaining('Viewing Archive:'), findsOneWidget);
      expect(find.text('Return to Today'), findsOneWidget);

      // Verify bottom nav unread badges are hidden in archive mode
      final feedProvider = Provider.of<FeedProvider>(
        tester.element(find.text('DAILY DEEP DIVES')),
        listen: false,
      );
      expect(feedProvider.isViewingArchive, isTrue);
      expect(feedProvider.unreadCounts['articles'], 0);

      // 5. Tap [ Return to Today ]
      await tester.tap(find.text('Return to Today'));
      await tester.pumpAndSettle();

      // 6. Archive banner removed and live state restored
      expect(find.textContaining('Viewing Archive:'), findsNothing);
      expect(feedProvider.isViewingArchive, isFalse);
    });
  });
}
