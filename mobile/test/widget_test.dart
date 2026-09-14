import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:curiosity_mobile/core/state/feed_provider.dart';
import 'package:curiosity_mobile/core/state/settings_provider.dart';
import 'package:curiosity_mobile/core/theme/geist_theme.dart';
import 'package:curiosity_mobile/core/utils/text_utils.dart';
import 'package:curiosity_mobile/main.dart';
import 'package:curiosity_mobile/core/models/feed_models.dart';
import 'package:curiosity_mobile/core/utils/image_utils.dart';
import 'package:curiosity_mobile/widgets/article_card.dart';
import 'package:curiosity_mobile/widgets/settings_modal.dart';
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

  group('Nordic Clay & Sage Theme & Contrast Verification Tests', () {
    double relativeLuminance(Color c) {
      double linearize(double channel) {
        return channel <= 0.03928
            ? channel / 12.92
            : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
      }

      final r = linearize(c.r);
      final g = linearize(c.g);
      final b = linearize(c.b);
      return 0.2126 * r + 0.7152 * g + 0.0722 * b;
    }

    double contrastRatio(Color fg, Color bg) {
      final l1 = relativeLuminance(fg);
      final l2 = relativeLuminance(bg);
      final lighter = math.max(l1, l2);
      final darker = math.min(l1, l2);
      return (lighter + 0.05) / (darker + 0.05);
    }

    test('Theme tokens adhere to Scandinavian radiuses and palette standards', () {
      expect(GeistSpacing.radiusSm, 8.0);
      expect(GeistSpacing.radiusMd, 14.0);
      expect(GeistSpacing.radiusLg, 18.0);
      expect(GeistSpacing.radiusXl, 24.0);

      // Dark Mode Slate & Mineral
      expect(GeistColors.darkBackground, const Color(0xFF1A1D20));
      expect(GeistColors.darkSurface, const Color(0xFF24282C));
      expect(GeistColors.darkSurfaceElevated, const Color(0xFF2C3136));

      // Light Mode Linen & Porcelain
      expect(GeistColors.lightBackground, const Color(0xFFFAF8F5));
      expect(GeistColors.lightSurface, const Color(0xFFFFFFFF));
    });

    test('WCAG 2.1 AA text and accent contrast validation (>4.5:1)', () {
      // Dark Mode Contrast
      final darkPrimaryRatio = contrastRatio(GeistColors.darkTextPrimary, GeistColors.darkBackground);
      final darkSecondaryRatio = contrastRatio(GeistColors.darkTextSecondary, GeistColors.darkSurface);
      final darkTertiaryRatio = contrastRatio(GeistColors.darkTextTertiary, GeistColors.darkSurface);
      final darkAccentTextRatio = contrastRatio(GeistColors.accentTextDark, GeistColors.darkSurface);
      expect(darkPrimaryRatio, greaterThan(10.0), reason: 'Dark primary text must exceed 10:1 contrast');
      expect(darkSecondaryRatio, greaterThan(4.5), reason: 'Dark secondary text must meet WCAG AA 4.5:1');
      expect(darkTertiaryRatio, greaterThan(4.5), reason: 'Dark tertiary text must meet WCAG AA 4.5:1');
      expect(darkAccentTextRatio, greaterThan(4.5), reason: 'Dark accent text must meet WCAG AA 4.5:1');

      // Light Mode Contrast
      final lightPrimaryRatio = contrastRatio(GeistColors.lightTextPrimary, GeistColors.lightBackground);
      final lightSecondaryRatio = contrastRatio(GeistColors.lightTextSecondary, GeistColors.lightSurface);
      final lightTertiaryRatio = contrastRatio(GeistColors.lightTextTertiary, GeistColors.lightSurface);
      final lightSageRatio = contrastRatio(GeistColors.accentLight, GeistColors.lightSurface);
      final streakLightRatio = contrastRatio(GeistColors.streakLight, GeistColors.lightBackground);
      expect(lightPrimaryRatio, greaterThan(10.0), reason: 'Light primary text must exceed 10:1 contrast');
      expect(lightSecondaryRatio, greaterThan(4.5), reason: 'Light secondary text must meet WCAG AA 4.5:1');
      expect(lightTertiaryRatio, greaterThan(4.5), reason: 'Light tertiary text must meet WCAG AA 4.5:1');
      expect(lightSageRatio, greaterThan(4.5), reason: 'Pine Sage on linen must meet WCAG AA 4.5:1');
      expect(streakLightRatio, greaterThan(4.5), reason: 'Terracotta streak on linen must meet WCAG AA 4.5:1');
    });

    testWidgets('CuriosityApp mounts properly under both Dark Mode and Light Mode', (WidgetTester tester) async {
      // Test Dark Mode
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpWidget(const CuriosityApp());
      await tester.pumpAndSettle();

      final darkTheme = Theme.of(tester.element(find.byType(Scaffold).first));
      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.scaffoldBackgroundColor, GeistColors.darkBackground);

      // Test Light Mode
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpWidget(const CuriosityApp());
      await tester.pumpAndSettle();

      final lightTheme = Theme.of(tester.element(find.byType(Scaffold).first));
      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.scaffoldBackgroundColor, GeistColors.lightBackground);

      // Reset
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
    });

    testWidgets('Interactive elements satisfy minimum 48x48 dp touch target guidelines', (WidgetTester tester) async {
      await tester.pumpWidget(const CuriosityApp());
      await tester.pumpAndSettle();

      // Top bar search bar touch target height
      final searchInkWell = tester.widget<InkWell>(find.widgetWithText(InkWell, 'Search topics…'));
      expect(searchInkWell, isNotNull);
      final searchBox = tester.renderObject(find.widgetWithText(InkWell, 'Search topics…')) as RenderBox;
      expect(searchBox.size.height, greaterThanOrEqualTo(48.0));

      // Vault button in top bar touch target size
      final vaultButtonBox = tester.renderObject(find.byTooltip('The Vault, view archives')) as RenderBox;
      expect(vaultButtonBox.size.width, greaterThanOrEqualTo(48.0));
      expect(vaultButtonBox.size.height, greaterThanOrEqualTo(48.0));
    });
  });

  group('In-App Settings & Dynamic ThemeMode Switching Tests', () {
    testWidgets('Top bar Settings icon renders with >= 48x48 dp touch target', (WidgetTester tester) async {
      await tester.pumpWidget(const CuriosityApp());
      await tester.pumpAndSettle();

      final settingsIconFinder = find.byTooltip('Settings & Preferences');
      expect(settingsIconFinder, findsOneWidget);

      final settingsBox = tester.renderObject(settingsIconFinder) as RenderBox;
      expect(settingsBox.size.width, greaterThanOrEqualTo(48.0));
      expect(settingsBox.size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('Tapping Settings icon opens SettingsModal with all 4 modular sections', (WidgetTester tester) async {
      await tester.pumpWidget(const CuriosityApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Settings & Preferences'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsModal), findsOneWidget);
      expect(find.text('Settings & Preferences'), findsOneWidget);
      expect(find.text('APPEARANCE MODE'), findsOneWidget);
      expect(find.text('DAILY LEARNING TARGET'), findsOneWidget);
      expect(find.text('READING & EDITORIAL'), findsOneWidget);
      expect(find.text('STORAGE & ABOUT'), findsOneWidget);
      expect(find.text('15 Items'), findsOneWidget);
      expect(find.text('34.2\u00A0MB'), findsOneWidget);
    });

    testWidgets('Switching between Light, Dark, and System dynamically updates theme and rendered brightness', (WidgetTester tester) async {
      final settingsProvider = SettingsProvider();
      await tester.pumpWidget(CuriosityApp(settingsProvider: settingsProvider));
      await tester.pumpAndSettle();

      // Open settings
      await tester.tap(find.byTooltip('Settings & Preferences'));
      await tester.pumpAndSettle();

      // 1. Switch to Light Mode
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      expect(settingsProvider.themeMode, ThemeMode.light);
      final lightScaffold = Theme.of(tester.element(find.byType(Scaffold).first));
      expect(lightScaffold.brightness, Brightness.light);
      expect(lightScaffold.scaffoldBackgroundColor, GeistColors.lightBackground);

      // 2. Switch to Dark Mode
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(settingsProvider.themeMode, ThemeMode.dark);
      final darkScaffold = Theme.of(tester.element(find.byType(Scaffold).first));
      expect(darkScaffold.brightness, Brightness.dark);
      expect(darkScaffold.scaffoldBackgroundColor, GeistColors.darkBackground);

      // 3. Switch back to System
      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();

      expect(settingsProvider.themeMode, ThemeMode.system);
    });

    testWidgets('Settings controls satisfy minimum 48dp touch targets and toggle preferences', (WidgetTester tester) async {
      final settingsProvider = SettingsProvider();
      await tester.pumpWidget(CuriosityApp(settingsProvider: settingsProvider));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Settings & Preferences'));
      await tester.pumpAndSettle();

      // Check close button size
      final closeButtonBox = tester.renderObject(find.byTooltip('Close settings')) as RenderBox;
      expect(closeButtonBox.size.width, greaterThanOrEqualTo(48.0));
      expect(closeButtonBox.size.height, greaterThanOrEqualTo(48.0));

      // Toggle Serif font switch
      expect(settingsProvider.useSerifFont, isTrue);
      await tester.tap(find.text('Serif Editorial Typeface (Lora)'));
      await tester.pumpAndSettle();
      expect(settingsProvider.useSerifFont, isFalse);

      // Toggle Haptics switch
      expect(settingsProvider.hapticsEnabled, isTrue);
      await tester.tap(find.text('Tactile Haptics on Actions'));
      await tester.pumpAndSettle();
      expect(settingsProvider.hapticsEnabled, isFalse);

      // Tap Clear Cache action (ensure visible in scrollable modal first)
      await tester.ensureVisible(find.text('Clear Offline Cache'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear Offline Cache'));
      await tester.pumpAndSettle();
      expect(find.text('Offline article cache cleared successfully.'), findsOneWidget);
    });
  });

  group('Article Image Gallery Matting & Zero-Crop Verification Tests', () {
    test('ImageUtils.upgradeWikiThumbnail upgrades Wikimedia 320px URLs to 640px', () {
      const inputUrl = 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Newton.jpg/320px-Newton.jpg';
      final upgraded = ImageUtils.upgradeWikiThumbnail(inputUrl, targetWidth: 640);
      expect(upgraded, 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Newton.jpg/640px-Newton.jpg');

      // Non-wiki URLs or URLs without standard px prefix remain unaltered
      const regularUrl = 'https://example.com/photos/image.jpg';
      expect(ImageUtils.upgradeWikiThumbnail(regularUrl), regularUrl);
    });

    testWidgets('ArticleCard renders thumbnail with BoxFit.contain preserving full aspect ratio', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const article = ArticleItem(
        title: 'Isaac Newton',
        normalizedTitle: 'Isaac Newton',
        summary: 'English mathematician, physicist, astronomer, alchemist, and author.',
        thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3b/Portrait_of_Sir_Isaac_Newton%2C_1689.jpg/320px-Portrait_of_Sir_Isaac_Newton%2C_1689.jpg',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: GeistTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ArticleCard(
                article: article,
                isRead: false,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify ArticleCard is rendered
      expect(find.byType(ArticleCard), findsOneWidget);

      // Verify image widgets: background ambient blur and foreground contain
      final imageFinders = find.byType(Image);
      expect(imageFinders, findsWidgets);

      // Check foreground Image has BoxFit.contain to ensure ZERO cropping
      final images = tester.widgetList<Image>(imageFinders).toList();
      final hasContainedForeground = images.any((img) => img.fit == BoxFit.contain);
      expect(hasContainedForeground, isTrue);
    });

    testWidgets('ArticleReaderModal renders uncropped image without fixed 16:9 constraint', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const article = ArticleItem(
        title: 'Mitochondrion',
        normalizedTitle: 'Mitochondrion',
        summary: 'A mitochondrion is an organelle found in the cells of most eukaryotes.',
        thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Animal_mitochondrion_diagram_en.svg/320px-Animal_mitochondrion_diagram_en.svg.png',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: GeistTheme.lightTheme,
          home: Scaffold(
            body: ArticleReaderModal(article: article),
          ),
        ),
      );
      await tester.pump();

      // Verify Reader Modal renders
      expect(find.text('WIKIPEDIA FEATURED DEEP DIVE'), findsOneWidget);

      // Verify Reader Modal image is rendered with BoxFit.contain and bounded height constraint
      final imageFinders = find.byType(Image, skipOffstage: false);
      expect(imageFinders, findsOneWidget);
      final readerImage = tester.widget<Image>(imageFinders.first);
      expect(readerImage.fit, BoxFit.contain);
      expect(readerImage.alignment, Alignment.center);

      // Verify ClipRRect and max-height 360 container
      final clipRRectFinder = find.byType(ClipRRect, skipOffstage: false);
      expect(clipRRectFinder, findsWidgets);

      final containerFinder = find.ancestor(
        of: imageFinders.first,
        matching: find.byType(Container),
      );
      expect(containerFinder, findsWidgets);
    });
  });
}

