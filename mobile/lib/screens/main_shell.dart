import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/feed_models.dart';
import '../core/state/feed_provider.dart';
import '../core/theme/geist_theme.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/command_palette_modal.dart';
import '../widgets/settings_modal.dart';
import '../widgets/top_bar.dart';
import 'articles_screen.dart';
import 'cosmos_screen.dart';
import 'facts_screen.dart';
import 'quizzes_screen.dart';
import 'vault_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentTabIndex = 0;

  void _onSearchPressed(BuildContext context) {
    CommandPaletteModal.show(context);
  }

  void _onVaultPressed(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const VaultScreen()),
    );
  }

  void _onSettingsPressed(BuildContext context) {
    SettingsModal.show(context);
  }

  Widget _buildArchiveBanner(BuildContext context, FeedProvider feedProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bannerBg = isDark ? const Color(0xFF2C3136) : const Color(0xFFEDE8E1);
    final bannerTextColor = isDark ? GeistColors.darkTextPrimary : GeistColors.lightTextPrimary;
    final buttonBg = isDark ? GeistColors.accent : GeistColors.accentLight;
    final buttonTextColor = isDark ? const Color(0xFF1A1D20) : Colors.white;
    final borderColor = isDark ? GeistColors.darkBorder : GeistColors.lightBorder;

    return Container(
      constraints: const BoxConstraints(minHeight: 44.0),
      padding: const EdgeInsets.symmetric(
        horizontal: GeistSpacing.md,
        vertical: GeistSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bannerBg,
        border: Border(
          bottom: BorderSide(
            color: borderColor,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Icon(Icons.history_rounded, size: 18.0, color: bannerTextColor),
          ),
          const SizedBox(width: GeistSpacing.xs),
          Expanded(
            child: Text(
              'Viewing Archive: ${feedProvider.archiveDate ?? ""}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w700,
                color: bannerTextColor,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: GeistSpacing.sm),
          Semantics(
            button: true,
            label: 'Return to Today feed',
            child: InkWell(
              onTap: () {
                feedProvider.returnToToday();
              },
              borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48.0, minWidth: 48.0),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: buttonBg,
                    borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
                  ),
                  child: Text(
                    'Return to Today',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w700,
                      color: buttonTextColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner(BuildContext context, FeedProvider feedProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bannerBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F1ED);
    final bannerTextColor = isDark ? GeistColors.darkTextSecondary : GeistColors.lightTextSecondary;
    final borderColor = isDark ? GeistColors.darkBorder : GeistColors.lightBorder;
    final retryColor = GeistColors.sage(isDark);

    final indicatorColor = switch (feedProvider.errorType) {
      FeedErrorType.offline => isDark ? const Color(0xFFE5A93C) : const Color(0xFFD48806),
      FeedErrorType.serverTimeout => isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
      FeedErrorType.serverIssue => isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
      FeedErrorType.none => isDark ? const Color(0xFFE5A93C) : const Color(0xFFD48806),
    };

    final message = feedProvider.statusBannerMessage.isNotEmpty
        ? feedProvider.statusBannerMessage
        : 'Offline • Showing saved pack';

    return Container(
      constraints: const BoxConstraints(minHeight: 38.0),
      padding: const EdgeInsets.symmetric(
        horizontal: GeistSpacing.md,
        vertical: 4.0,
      ),
      decoration: BoxDecoration(
        color: bannerBg,
        border: Border(
          bottom: BorderSide(
            color: borderColor,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6.0,
            height: 6.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: indicatorColor,
            ),
          ),
          const SizedBox(width: GeistSpacing.xs),
          Expanded(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                color: bannerTextColor,
                letterSpacing: -0.1,
              ),
            ),
          ),
          const SizedBox(width: GeistSpacing.xs),
          Semantics(
            button: true,
            label: 'Retry connection',
            child: InkWell(
              onTap: feedProvider.isSyncing
                  ? null
                  : () {
                      feedProvider.fetchDailyFeed();
                    },
              borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: feedProvider.isSyncing
                    ? SizedBox(
                        width: 12.0,
                        height: 12.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(retryColor),
                        ),
                      )
                    : Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w700,
                          color: retryColor,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<FeedProvider>();

    return Scaffold(
      appBar: GeistTopBar(
        onSearchTap: () => _onSearchPressed(context),
        onVaultTap: () => _onVaultPressed(context),
        onSettingsTap: () => _onSettingsPressed(context),
      ),
      body: Column(
        children: [
          if (feedProvider.isViewingArchive)
            _buildArchiveBanner(context, feedProvider)
          else if (feedProvider.isOffline)
            _buildOfflineBanner(context, feedProvider),
          Expanded(
            child: IndexedStack(
              index: _currentTabIndex,
              children: const [
                ArticlesScreen(),
                QuizzesScreen(),
                CosmosScreen(),
                FactsScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: GeistBottomNav(
        currentIndex: _currentTabIndex,
        onTabSelected: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        unreadCounts: feedProvider.unreadCounts,
      ),
    );
  }
}
