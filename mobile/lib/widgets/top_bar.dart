import 'package:flutter/material.dart';
import '../core/theme/geist_theme.dart';

class GeistTopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onVaultTap;

  const GeistTopBar({
    super.key,
    this.onSearchTap,
    this.onVaultTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? GeistColors.darkSurface : GeistColors.lightSurface;
    final borderColor = isDark ? GeistColors.darkBorder : GeistColors.lightBorder;
    final primaryTextColor = isDark ? GeistColors.darkTextPrimary : GeistColors.lightTextPrimary;
    final secondaryTextColor = isDark ? GeistColors.darkTextSecondary : GeistColors.lightTextSecondary;

    return SafeArea(
      bottom: false,
      child: Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(
          horizontal: GeistSpacing.md,
          vertical: GeistSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isDark ? GeistColors.darkBackground : GeistColors.lightBackground,
          border: Border(
            bottom: BorderSide(color: borderColor, width: 1.0),
          ),
        ),
        child: Row(
          children: [
            // Simulated Search Bar (Command Palette Trigger)
            Expanded(
              child: Semantics(
                button: true,
                label: 'Search topics, command palette',
                child: InkWell(
                  onTap: onSearchTap,
                  borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
                  child: Container(
                    height: 44.0,
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
                        const SizedBox(width: GeistSpacing.sm),
                        Text(
                          'Search topics…',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: secondaryTextColor,
                                fontSize: 13.5,
                              ),
                        ),
                        const Spacer(),
                        // Command Palette hint badge (Geist style)
                        ExcludeSemantics(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF222222) : const Color(0xFFE5E5E5),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              '⌘\u00A0K',
                              style: TextStyle(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w700,
                                color: secondaryTextColor,
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
                size: 20.0,
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
