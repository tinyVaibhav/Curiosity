import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/geist_theme.dart';

class GeistBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final Map<String, int> unreadCounts;

  const GeistBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.unreadCounts,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? GeistColors.darkBackground : GeistColors.lightBackground;
    final borderColor = isDark ? GeistColors.darkBorder : GeistColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GeistSpacing.sm,
              vertical: 4.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  index: 0,
                  label: 'Articles',
                  icon: Icons.article_outlined,
                  activeIcon: Icons.article_rounded,
                  badgeCount: unreadCounts['articles'] ?? 0,
                ),
                _buildNavItem(
                  context: context,
                  index: 1,
                  label: 'Quizzes',
                  icon: Icons.psychology_outlined,
                  activeIcon: Icons.psychology_rounded,
                  badgeCount: unreadCounts['quizzes'] ?? 0,
                ),
                _buildNavItem(
                  context: context,
                  index: 2,
                  label: 'Cosmos',
                  icon: Icons.auto_awesome_outlined,
                  activeIcon: Icons.auto_awesome_rounded,
                  badgeCount: unreadCounts['cosmos'] ?? 0,
                ),
                _buildNavItem(
                  context: context,
                  index: 3,
                  label: 'Facts',
                  icon: Icons.bolt_outlined,
                  activeIcon: Icons.bolt_rounded,
                  badgeCount: unreadCounts['facts'] ?? 0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required int badgeCount,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = currentIndex == index;
    final primaryColor = isDark ? GeistColors.darkTextPrimary : GeistColors.lightTextPrimary;
    final secondaryColor = isDark ? GeistColors.darkTextSecondary : GeistColors.lightTextSecondary;

    final unreadLabel = badgeCount > 0 ? '$badgeCount unread items' : 'all caught up';

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: '$label tab, $unreadLabel',
        child: InkResponse(
          containedInkWell: true,
          highlightShape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
          onTap: () {
            if (currentIndex != index) {
              HapticFeedback.lightImpact();
              onTabSelected(index);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon + Dynamic Unread Badge
                ExcludeSemantics(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        isSelected ? activeIcon : icon,
                        size: 22.0,
                        color: isSelected ? primaryColor : secondaryColor,
                      ),
                      // Badge overlay
                      if (badgeCount > 0)
                        Positioned(
                          top: -4.0,
                          right: -10.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF222222) : const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(
                                color: isDark ? GeistColors.darkBorderActive : GeistColors.lightBorderActive,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '$badgeCount',
                              style: TextStyle(
                                fontSize: 10.0,
                                fontWeight: FontWeight.w700,
                                color: isDark ? GeistColors.darkTextPrimary : GeistColors.lightTextPrimary,
                                height: 1.0,
                              ),
                            ),
                          ),
                        )
                      else
                        // "Inbox Zero" subtle completion indicator
                        Positioned(
                          top: -2.0,
                          right: -6.0,
                          child: Container(
                            width: 5.0,
                            height: 5.0,
                            decoration: const BoxDecoration(
                              color: GeistColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 3.0),
                // Label
                ExcludeSemantics(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      letterSpacing: -0.2,
                      color: isSelected ? primaryColor : secondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
