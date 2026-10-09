import 'package:flutter/material.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? GeistColors.darkBackground : GeistColors.lightBackground;
    final surfaceColor = isDark ? GeistColors.darkSurface : GeistColors.lightSurface;
    final borderColor = isDark ? GeistColors.darkBorder : GeistColors.lightBorder;
    final primaryTextColor = isDark ? GeistColors.darkTextPrimary : GeistColors.lightTextPrimary;
    final secondaryTextColor = isDark ? GeistColors.darkTextSecondary : GeistColors.lightTextSecondary;

    return Container(
      color: backgroundColor,
      child: SafeArea(
        top: true,
        bottom: false,
        child: Container(
          height: 60.0,
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(bottom: BorderSide(color: borderColor, width: 1.0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left Side: Brand Logo and Title (Editorial Masthead)
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22.0,
                      height: 22.0,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: primaryTextColor,
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: Text(
                        'C',
                        style: TextStyle(
                          color: backgroundColor,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Flexible(
                      child: Text(
                        'CURIOSITY',
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          letterSpacing: 1.2,
                          color: primaryTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Right Side: Calibrated Utility Trio (Vault, Search, Settings)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The Vault Action Button
                  IconButton(
                    onPressed: onVaultTap,
                    tooltip: 'The Vault, view archives',
                    constraints: const BoxConstraints(minWidth: 44.0, minHeight: 48.0),
                    padding: EdgeInsets.zero,
                    icon: Container(
                      width: 30.0,
                      height: 30.0,
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(7.0),
                        border: Border.all(color: borderColor, width: 1.0),
                      ),
                      child: Icon(Icons.calendar_today_outlined, size: 15.0, color: secondaryTextColor),
                    ),
                  ),
                  const SizedBox(width: 2.0),

                  // Command Search Action Button
                  IconButton(
                    onPressed: onSearchTap,
                    tooltip: 'Search topics, command palette',
                    constraints: const BoxConstraints(minWidth: 44.0, minHeight: 48.0),
                    padding: EdgeInsets.zero,
                    icon: Container(
                      width: 30.0,
                      height: 30.0,
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(7.0),
                        border: Border.all(color: borderColor, width: 1.0),
                      ),
                      child: Icon(Icons.search_rounded, size: 15.0, color: secondaryTextColor),
                    ),
                  ),
                  const SizedBox(width: 2.0),

                  // Settings Action Button
                  IconButton(
                    onPressed: onSettingsTap,
                    tooltip: 'Settings & Preferences',
                    constraints: const BoxConstraints(minWidth: 44.0, minHeight: 48.0),
                    padding: EdgeInsets.zero,
                    icon: Container(
                      width: 30.0,
                      height: 30.0,
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(7.0),
                        border: Border.all(color: borderColor, width: 1.0),
                      ),
                      child: Icon(Icons.tune_rounded, size: 15.0, color: secondaryTextColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
