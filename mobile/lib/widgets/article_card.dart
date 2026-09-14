import 'dart:ui' show ImageFilter;
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
                // 1. Gallery Matting Thumbnail with Ambient Backdrop (Option 1)
                _buildThumbnail(isDark, secondaryTextColor),

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
                            color: isDark ? const Color(0xFF2C3136) : const Color(0xFFEDE8E1),
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
                            color: isDark ? GeistColors.accentTextDark : GeistColors.accentLight,
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

  Widget _buildThumbnail(bool isDark, Color secondaryTextColor) {
    if (article.thumbnailUrl == null || article.thumbnailUrl!.trim().isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: ExcludeSemantics(
          child: _buildPlaceholder(isDark, secondaryTextColor),
        ),
      );
    }

    final imageUrl = ImageUtils.resolveImageUrl(article.thumbnailUrl!);
    final canvasColor = isDark ? const Color(0xFF191C1F) : const Color(0xFFEDE8E1);
    final scrimColor = isDark ? const Color(0x99191C1F) : const Color(0x99F5F0EB);

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ExcludeSemantics(
        child: Container(
          color: canvasColor,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Ambient blurred background glow from image palette
              ClipRect(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
                  child: Transform.scale(
                    scale: 1.25,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

              // 2. Soft tinted scrim for harmonious ambient contrast
              Container(color: scrimColor),

              // 3. Foreground uncropped image (100% visible, zero cropping)
              Image.network(
                imageUrl,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _buildSkeleton(isDark);
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder(isDark, secondaryTextColor);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF24282C) : const Color(0xFFF2EFE9),
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
    final backgroundColor = isDark ? GeistColors.darkModalBackground : GeistColors.lightModalBackground;
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
                  color: isDark ? const Color(0xFF33383F) : const Color(0xFFD6CFC7),
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
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 360.0),
                      width: double.infinity,
                      color: isDark ? const Color(0xFF191C1F) : const Color(0xFFEDE8E1),
                      child: ExcludeSemantics(
                        child: Image.network(
                          ImageUtils.resolveImageUrl(article.thumbnailUrl!),
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return SizedBox(
                              height: 180.0,
                              child: Center(
                                child: SizedBox(
                                  width: 24.0,
                                  height: 24.0,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
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
                        color: isDark ? GeistColors.darkSurfaceElevated : GeistColors.lightSurfaceElevated,
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

                // Title with Semantics Header
                Semantics(
                  header: true,
                  child: Text(
                    displayTitle,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 24.0,
                          color: primaryTextColor,
                          height: 1.2,
                        ),
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

                // Action: Open in Browser - 48dp Touch Target
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
                      backgroundColor: isDark ? GeistColors.accent : GeistColors.accentLight,
                      foregroundColor: isDark ? const Color(0xFF1A1D20) : Colors.white,
                      minimumSize: const Size.fromHeight(48.0),
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(GeistSpacing.radiusLg),
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
