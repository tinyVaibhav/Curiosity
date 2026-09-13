import 'package:flutter/material.dart';
import '../core/models/feed_models.dart';
import '../core/theme/geist_theme.dart';
import '../core/utils/image_utils.dart';

class VaultHistoryCard extends StatelessWidget {
  final VaultHistoryItem item;
  final VoidCallback onTap;
  final bool isLoading;

  const VaultHistoryCard({
    super.key,
    required this.item,
    required this.onTap,
    this.isLoading = false,
  });

  String _formatDate(String isoDate) {
    try {
      final parts = isoDate.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        final dt = DateTime(year, month, day);

        const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

        final weekday = weekdays[dt.weekday - 1];
        final monthName = months[month - 1];
        return '$weekday, $monthName $day, $year';
      }
    } catch (_) {}
    return isoDate;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? GeistColors.darkSurface : GeistColors.lightSurface;
    final borderColor = isDark ? GeistColors.darkBorder : GeistColors.lightBorder;
    final primaryTextColor = isDark ? GeistColors.darkTextPrimary : GeistColors.lightTextPrimary;
    final secondaryTextColor = isDark ? GeistColors.darkTextSecondary : GeistColors.lightTextSecondary;

    final formattedDate = _formatDate(item.packDate);
    final articlesPreview = item.articleTitles.isNotEmpty
        ? item.articleTitles.take(2).join(' · ')
        : 'Daily Discovery Pack';

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        label: 'Vault edition for $formattedDate. $articlesPreview',
        child: InkWell(
          onTap: isLoading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(GeistSpacing.md),
            child: Row(
              children: [
                // Mini Leading Thumbnail (or Icon Fallback)
                ExcludeSemantics(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
                    child: Container(
                      width: 44.0,
                      height: 44.0,
                      color: isDark ? const Color(0xFF222222) : const Color(0xFFE5E5E5),
                      child: (item.heroThumbnailUrl != null && item.heroThumbnailUrl!.isNotEmpty)
                          ? Image.network(
                              ImageUtils.resolveImageUrl(item.heroThumbnailUrl!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.calendar_today_rounded,
                                size: 20.0,
                                color: secondaryTextColor,
                              ),
                            )
                          : Icon(
                              Icons.calendar_today_rounded,
                              size: 20.0,
                              color: secondaryTextColor,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: GeistSpacing.md),

                // Date Header & Article Previews
                Expanded(
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formattedDate,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3.0),
                        Text(
                          articlesPreview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w400,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: GeistSpacing.sm),

                // Trailing Indicator / Spinner
                ExcludeSemantics(
                  child: isLoading
                      ? SizedBox(
                          width: 18.0,
                          height: 18.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: primaryTextColor,
                          ),
                        )
                      : Icon(
                          Icons.chevron_right_rounded,
                          size: 20.0,
                          color: secondaryTextColor,
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
