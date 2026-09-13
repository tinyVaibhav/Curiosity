import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models/feed_models.dart';
import '../core/theme/geist_theme.dart';
import '../core/utils/image_utils.dart';
import '../core/utils/text_utils.dart';

class ArticleCard extends StatelessWidget {
  final ArticleItem article;
  final bool isRead;
  final VoidCallback onTap;

  const ArticleCard({
    super.key,
    required this.article,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? GeistColors.darkSurface : GeistColors.lightSurface;
    final borderColor = isDark
        ? (isRead ? GeistColors.darkBorder : GeistColors.darkBorderActive)
        : (isRead ? GeistColors.lightBorder : GeistColors.lightBorderActive);
    final primaryTextColor = isDark ? GeistColors.darkTextPrimary : GeistColors.lightTextPrimary;
    final secondaryTextColor = isDark ? GeistColors.darkTextSecondary : GeistColors.lightTextSecondary;

    final displayTitle = TextUtils.cleanWikiTitle(
      article.normalizedTitle.isNotEmpty ? article.normalizedTitle : article.title,
    );

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(GeistSpacing.radiusLg),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: MergeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.transparent,
            highlightColor: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 16:9 Thumbnail with skeleton loader
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: article.thumbnailUrl != null && article.thumbnailUrl!.isNotEmpty
                      ? Image.network(
                          ImageUtils.resolveImageUrl(article.thumbnailUrl!),
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return _buildSkeleton(isDark);
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholder(isDark, secondaryTextColor);
                          },
                        )
                      : _buildPlaceholder(isDark, secondaryTextColor),
                ),

              // 2. Card Content
              Padding(
                padding: const EdgeInsets.all(GeistSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Category Pill & Read Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E8E8),
                            borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
                          ),
                          child: Text(
                            '#ARTICLE',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  letterSpacing: 0.8,
                                  fontSize: 10.0,
                                ),
                          ),
                        ),
                        if (isRead)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_rounded, size: 14.0, color: GeistColors.success),
                              SizedBox(width: 3.0),
                              Text(
                                'Read',
                                style: TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700,
                                  color: GeistColors.success,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: GeistSpacing.sm),

                    // Title
                    Text(
                      displayTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: primaryTextColor,
                            height: 1.25,
                          ),
                    ),
                    const SizedBox(height: GeistSpacing.sm),

                    // 3-Line Clamped Description
                    Text(
                      article.summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: secondaryTextColor,
                            height: 1.45,
                          ),
                    ),
                    const SizedBox(height: GeistSpacing.md),

                    // CTA: Read Full Article ↗
                    Row(
                      children: [
                        Text(
                          'Read Full Article ↗',
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildSkeleton(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE5E5E5),
      child: Center(
        child: SizedBox(
          width: 20.0,
          height: 20.0,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            color: isDark ? GeistColors.darkTextSecondary : GeistColors.lightTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark, Color secondaryColor) {
    return Container(
      color: isDark ? const Color(0xFF161616) : const Color(0xFFEEEEEE),
      child: Center(
        child: Icon(
          Icons.article_outlined,
          size: 36.0,
          color: secondaryColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// In-App Article Reader Modal
class ArticleReaderModal extends StatelessWidget {
  final ArticleItem article;

  const ArticleReaderModal({
    super.key,
    required this.article,
  });

  static Future<void> show(BuildContext context, ArticleItem article) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ArticleReaderModal(article: article),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? GeistColors.darkBackground : GeistColors.lightBackground;
    final surfaceColor = isDark ? GeistColors.darkSurface : GeistColors.lightSurface;
    final primaryTextColor = isDark ? GeistColors.darkTextPrimary : GeistColors.lightTextPrimary;
    final secondaryTextColor = isDark ? GeistColors.darkTextSecondary : GeistColors.lightTextSecondary;
    final borderColor = isDark ? GeistColors.darkBorder : GeistColors.lightBorder;

    final displayTitle = TextUtils.cleanWikiTitle(
      article.normalizedTitle.isNotEmpty ? article.normalizedTitle : article.title,
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(GeistSpacing.radiusLg)),
        border: Border(top: BorderSide(color: borderColor, width: 1.0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Drag handle bar
          ExcludeSemantics(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: GeistSpacing.sm),
              alignment: Alignment.center,
              child: Container(
                width: 36.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF333333) : const Color(0xFFCCCCCC),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
          ),

          // Scrollable reader body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: GeistSpacing.lg),
              children: [
                if (article.thumbnailUrl != null && article.thumbnailUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        ImageUtils.resolveImageUrl(article.thumbnailUrl!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  const SizedBox(height: GeistSpacing.md),
                ],

                // Header Pill & Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
                        border: Border.all(color: borderColor, width: 1.0),
                      ),
                      child: Text(
                        'WIKIPEDIA FEATURED DEEP DIVE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10.0),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close modal',
                      icon: const Icon(Icons.close_rounded, size: 22.0),
                      color: secondaryTextColor,
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(48.0, 48.0),
                        padding: const EdgeInsets.all(12.0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GeistSpacing.sm),

                // Title
                Text(
                  displayTitle,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 24.0,
                        color: primaryTextColor,
                        height: 1.2,
                      ),
                ),
                const SizedBox(height: GeistSpacing.md),

                // Summary content
                Text(
                  article.summary,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: secondaryTextColor,
                        fontSize: 16.0,
                        height: 1.6,
                      ),
                ),
                const SizedBox(height: GeistSpacing.xl),

                // Action: Open in Browser
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse(TextUtils.formatWikipediaUrl(article.title));
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.inAppBrowserView);
                      }
                    },
                    icon: const Icon(Icons.open_in_browser_rounded, size: 18.0),
                    label: const Text(
                      'Open Full Wikipedia Article ↗',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTextColor,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: GeistSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
