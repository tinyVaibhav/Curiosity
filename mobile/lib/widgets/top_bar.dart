import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/state/feed_provider.dart';
import '../core/theme/geist_theme.dart';

class GeistTopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onVaultTap;
  final VoidCallback onSettingsTap;

  const GeistTopBar({
    super.key,
    required this.onSearchTap,
    required this.onVaultTap,
    required this.onSettingsTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<FeedProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? GeistColors.darkBackground : GeistColors.lightBackground;
    final surfaceColor = isDark ? GeistColors.darkSurface : GeistColors.lightSurface;
    final borderColor = isDark ? GeistColors.darkBorder : GeistColors.lightBorder;
    final primaryTextColor = isDark ? GeistColors.darkTextPrimary : GeistColors.lightTextPrimary;
    final secondaryTextColor = isDark ? GeistColors.darkTextSecondary : GeistColors.lightTextSecondary;

    return SafeArea(
      child: Container(
        height: 60.0,
        padding: const EdgeInsets.symmetric(horizontal: GeistSpacing.md),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(bottom: BorderSide(color: borderColor, width: 1.0)),
        ),
        child: Row(
          children: [
            // Ambient Completion Ring
            _AmbientProgressRing(
              completed: feedProvider.completedCount,
              total: 15,
              progressColor: isDark ? GeistColors.accent : GeistColors.accentLight,
              trackColor: isDark ? const Color(0x335B8A72) : const Color(0x243E6552),
              textColor: primaryTextColor,
            ),
            const SizedBox(width: GeistSpacing.sm),

            // Streak Flame Counter (Terracotta accent)
            Semantics(
              label: '7 day learning streak',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x2CD97757) : const Color(0x1FC85A32),
                  borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
                  border: Border.all(
                    color: isDark ? const Color(0x44D97757) : const Color(0x33C85A32),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 13.0)),
                    const SizedBox(width: 3.0),
                    Text(
                      '7',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? GeistColors.streak : GeistColors.streakLight,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: GeistSpacing.sm),

            // Simulated Search Bar (Command Palette Trigger) - 48dp Touch Target
            Expanded(
              child: Semantics(
                button: true,
                label: 'Search topics, command palette',
                child: InkWell(
                  onTap: onSearchTap,
                  borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
                  child: Container(
                    height: 48.0,
                    padding: const EdgeInsets.symmetric(horizontal: GeistSpacing.md),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
                      border: Border.all(color: borderColor, width: 1.0),
                    ),
                    child: Row(
                      children: [
                        ExcludeSemantics(
                          child: Icon(
                            Icons.search_rounded,
                            size: 18.0,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(width: GeistSpacing.xs),
                        Expanded(
                          child: Text(
                            'Search topics…',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: secondaryTextColor,
                                  fontSize: 13.0,
                                ),
                          ),
                        ),
                        // Command Palette hint badge
                        ExcludeSemantics(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
                            decoration: BoxDecoration(
                              color: isDark ? GeistColors.darkSurfaceElevated : GeistColors.lightSurfaceElevated,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              '⌘\u00A0K',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: primaryTextColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: GeistSpacing.sm),

            // The Vault / Calendar Archive Action Button
            IconButton(
              onPressed: onVaultTap,
              tooltip: 'The Vault, view archives',
              constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
              icon: Icon(
                Icons.calendar_today_outlined,
                size: 19.0,
                color: primaryTextColor,
              ),
              style: IconButton.styleFrom(
                backgroundColor: surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
                  side: BorderSide(color: borderColor, width: 1.0),
                ),
                padding: const EdgeInsets.all(10.0),
              ),
            ),
            const SizedBox(width: GeistSpacing.xs),

            // Settings & Appearance Action Button
            IconButton(
              onPressed: onSettingsTap,
              tooltip: 'Settings & Preferences',
              constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
              icon: Icon(
                Icons.tune_rounded,
                size: 19.0,
                color: primaryTextColor,
              ),
              style: IconButton.styleFrom(
                backgroundColor: surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
                  side: BorderSide(color: borderColor, width: 1.0),
                ),
                padding: const EdgeInsets.all(10.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientProgressRing extends StatelessWidget {
  final int completed;
  final int total;
  final Color progressColor;
  final Color trackColor;
  final Color textColor;

  const _AmbientProgressRing({
    required this.completed,
    required this.total,
    required this.progressColor,
    required this.trackColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;

    return Semantics(
      label: 'Daily progress: $completed of $total completed',
      child: SizedBox(
        width: 38.0,
        height: 38.0,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 2.8,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
            Text(
              '$completed/$total',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: -0.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
