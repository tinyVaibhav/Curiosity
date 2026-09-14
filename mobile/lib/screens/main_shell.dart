import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
            _buildArchiveBanner(context, feedProvider),
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
