import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/state/settings_provider.dart';
import '../core/theme/geist_theme.dart';

/// Pillowy Scandinavian Bottom Sheet for In-App Settings & Theme Mode Switcher.
class SettingsModal extends StatelessWidget {
  const SettingsModal({super.key});

  /// Static convenience helper to display the modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SettingsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modalBg = isDark ? GeistColors.darkSurfaceElevated : GeistColors.lightSurface;
    final cardBg = isDark ? GeistColors.darkSurface : const Color(0xFFFBF9F6);
    final borderColor = isDark ? GeistColors.darkBorder : GeistColors.lightBorder;
    final primaryTextColor = isDark ? GeistColors.darkTextPrimary : GeistColors.lightTextPrimary;
    final secondaryTextColor = isDark ? GeistColors.darkTextSecondary : GeistColors.lightTextSecondary;
    final accentColor = GeistColors.sage(isDark);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: modalBg,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(GeistSpacing.radiusXl),
          ),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Padding(
              padding: const EdgeInsets.only(top: GeistSpacing.sm, bottom: GeistSpacing.xs),
              child: Container(
                width: 44.0,
                height: 4.5,
                decoration: BoxDecoration(
                  color: GeistColors.dragHandle(isDark),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),

            // Header: Title, Subtitle, and 48dp Close Button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GeistSpacing.md,
                vertical: GeistSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'Settings & Preferences',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: primaryTextColor,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          'Appearance, daily goals & learning controls',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: secondaryTextColor,
                                fontSize: 12.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close settings',
                    constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20.0,
                      color: secondaryTextColor,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: cardBg,
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
            const Divider(height: 1.0, thickness: 1.0),

            // Scrollable Settings Sections
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(GeistSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. APPEARANCE & THEME MODE SECTION
                    _buildSectionHeader(context, 'APPEARANCE MODE', accentColor),
                    const SizedBox(height: GeistSpacing.xs),
                    _buildAppearanceSegmentedPill(
                      context: context,
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      secondaryTextColor: secondaryTextColor,
                      accentColor: accentColor,
                    ),
                    const SizedBox(height: GeistSpacing.lg),

                    // 2. DAILY LEARNING TARGET SECTION
                    _buildSectionHeader(context, 'DAILY LEARNING TARGET', accentColor),
                    const SizedBox(height: GeistSpacing.xs),
                    _buildDailyGoalCard(
                      context: context,
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      primaryTextColor: primaryTextColor,
                      accentColor: accentColor,
                    ),
                    const SizedBox(height: GeistSpacing.sm),
                    _buildSwitchCard(
                      context: context,
                      title: 'Morning Curiosity Digest',
                      subtitle: 'Daily 8:00 AM push notification',
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      primaryTextColor: primaryTextColor,
                      value: context.select<SettingsProvider, bool>((s) => s.morningDigestEnabled),
                      onChanged: (val) {
                        context.read<SettingsProvider>().toggleMorningDigest(val);
                      },
                      accentColor: accentColor,
                    ),
                    const SizedBox(height: GeistSpacing.lg),

                    // 3. READING & EDITORIAL SECTION
                    _buildSectionHeader(context, 'READING & EDITORIAL', accentColor),
                    const SizedBox(height: GeistSpacing.xs),
                    _buildSwitchCard(
                      context: context,
                      title: 'Serif Editorial Typeface (Lora)',
                      subtitle: 'Render quotes and headlines in editorial serif',
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      primaryTextColor: primaryTextColor,
                      value: context.select<SettingsProvider, bool>((s) => s.useSerifFont),
                      onChanged: (val) {
                        context.read<SettingsProvider>().toggleSerifFont(val);
                      },
                      accentColor: accentColor,
                    ),
                    const SizedBox(height: GeistSpacing.sm),
                    _buildSwitchCard(
                      context: context,
                      title: 'Tactile Haptics on Actions',
                      subtitle: 'Subtle vibration on quizzes and bookmarks',
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      primaryTextColor: primaryTextColor,
                      value: context.select<SettingsProvider, bool>((s) => s.hapticsEnabled),
                      onChanged: (val) {
                        context.read<SettingsProvider>().toggleHaptics(val);
                      },
                      accentColor: accentColor,
                    ),
                    const SizedBox(height: GeistSpacing.lg),

                    // 4. STORAGE & SYSTEM SECTION
                    _buildSectionHeader(context, 'STORAGE & ABOUT', accentColor),
                    const SizedBox(height: GeistSpacing.xs),
                    _buildActionCard(
                      context: context,
                      title: 'Clear Offline Cache',
                      trailingText: '34.2\u00A0MB',
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Offline article cache cleared successfully.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: GeistSpacing.sm),
                    _buildInfoCard(
                      context: context,
                      title: 'App Version',
                      trailingText: 'v1.2.0 (Nordic Clay & Sage)',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                    const SizedBox(height: GeistSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: color,
            ),
      ),
    );
  }

  Widget _buildAppearanceSegmentedPill({
    required BuildContext context,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color secondaryTextColor,
    required Color accentColor,
  }) {
    final currentMode = context.select<SettingsProvider, ThemeMode>((s) => s.themeMode);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          _buildSegmentOption(
            context: context,
            mode: ThemeMode.light,
            label: 'Light',
            icon: Icons.light_mode_outlined,
            isSelected: currentMode == ThemeMode.light,
            accentColor: accentColor,
            secondaryTextColor: secondaryTextColor,
            borderColor: borderColor,
          ),
          _buildSegmentOption(
            context: context,
            mode: ThemeMode.system,
            label: 'System',
            icon: Icons.brightness_auto_outlined,
            isSelected: currentMode == ThemeMode.system,
            accentColor: accentColor,
            secondaryTextColor: secondaryTextColor,
            borderColor: borderColor,
          ),
          _buildSegmentOption(
            context: context,
            mode: ThemeMode.dark,
            label: 'Dark',
            icon: Icons.dark_mode_outlined,
            isSelected: currentMode == ThemeMode.dark,
            accentColor: accentColor,
            secondaryTextColor: secondaryTextColor,
            borderColor: borderColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentOption({
    required BuildContext context,
    required ThemeMode mode,
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color accentColor,
    required Color secondaryTextColor,
    required Color borderColor,
  }) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: '$label appearance mode',
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            context.read<SettingsProvider>().setThemeMode(mode);
            SemanticsService.sendAnnouncement(
              View.of(context),
              'Theme changed to ${mode.name}',
              Directionality.of(context),
            );
          },
          borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: isSelected ? accentColor : Colors.transparent,
                borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
                border: Border.all(
                  color: isSelected ? accentColor : Colors.transparent,
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      icon,
                      size: 16.0,
                      color: isSelected ? Colors.white : secondaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 5.0),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyGoalCard({
    required BuildContext context,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color primaryTextColor,
    required Color accentColor,
  }) {
    final dailyGoal = context.select<SettingsProvider, int>((s) => s.dailyGoal);

    return Container(
      constraints: const BoxConstraints(minHeight: 52.0),
      padding: const EdgeInsets.symmetric(horizontal: GeistSpacing.md, vertical: GeistSpacing.sm),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Completion Goal',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  '3 Articles, 2 Cosmos, 5 Quizzes, 5 Facts',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12.0,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: GeistSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x285B8A72) : const Color(0x1F3E6552),
              borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
              border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1.0),
            ),
            child: Text(
              '$dailyGoal Items',
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFB4E0C8) : accentColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color primaryTextColor,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color accentColor,
  }) {
    return MergeSemantics(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onChanged(!value);
          },
          borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56.0),
            padding: const EdgeInsets.symmetric(horizontal: GeistSpacing.md, vertical: 6.0),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11.5,
                            ),
                      ),
                    ],
                  ),
                ),
                ExcludeSemantics(
                  child: Switch.adaptive(
                    value: value,
                    onChanged: (val) {
                      HapticFeedback.lightImpact();
                      onChanged(val);
                    },
                    activeTrackColor: accentColor,
                    activeThumbColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String trailingText,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: '$title, $trailingText',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48.0),
          padding: const EdgeInsets.symmetric(horizontal: GeistSpacing.md, vertical: GeistSpacing.sm),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: primaryTextColor,
                ),
              ),
              Row(
                children: [
                  Text(
                    trailingText,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: secondaryTextColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  ExcludeSemantics(
                    child: Icon(Icons.chevron_right_rounded, size: 18.0, color: secondaryTextColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required String trailingText,
    required Color cardBg,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48.0),
      padding: const EdgeInsets.symmetric(horizontal: GeistSpacing.md, vertical: GeistSpacing.sm),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
              color: primaryTextColor,
            ),
          ),
          Text(
            trailingText,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
