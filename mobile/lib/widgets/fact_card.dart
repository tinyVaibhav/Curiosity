import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../core/models/feed_models.dart';
import '../core/theme/geist_theme.dart';

class FactCard extends StatefulWidget {
  final FactItem fact;
  final int factIndex;
  final bool isRead;
  final VoidCallback onViewed;

  const FactCard({
    super.key,
    required this.fact,
    required this.factIndex,
    required this.isRead,
    required this.onViewed,
  });

  @override
  State<FactCard> createState() => _FactCardState();
}

class _FactCardState extends State<FactCard> {
  Timer? _visibilityTimer;
  bool _isBookmarked = false;

  @override
  void dispose() {
    _visibilityTimer?.cancel();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (widget.isRead) return;

    if (info.visibleFraction >= 0.65) {
      // Start 1-second dwell timer
      _visibilityTimer ??= Timer(const Duration(milliseconds: 1000), () {
        if (mounted && !widget.isRead) {
          widget.onViewed();
        }
      });
    } else {
      // Scrolled out of view before 1s dwell
      _visibilityTimer?.cancel();
      _visibilityTimer = null;
    }
  }

  Future<void> _handleShare(BuildContext context) async {
    HapticFeedback.lightImpact();
    final shareText = '“${widget.fact.text}” — via Curiosity App';

    try {
      await SharePlus.instance.share(ShareParams(text: shareText, subject: 'Curiosity Daily Fact'));
    } catch (_) {
      // Fallback for environments where native share sheet is unavailable (e.g., Desktop/Web testing)
      await Clipboard.setData(ClipboardData(text: shareText));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Fact copied to clipboard 📋',
              style: TextStyle(color: GeistColors.darkTextPrimary),
            ),
            backgroundColor: GeistColors.darkSurface,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
              side: const BorderSide(color: GeistColors.darkBorder),
            ),
          ),
        );
      }
    }
  }

  void _toggleBookmark(BuildContext context) {
    HapticFeedback.selectionClick();
    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isBookmarked ? 'Saved to Vault bookmarks 🔖' : 'Removed from bookmarks',
          style: const TextStyle(color: GeistColors.darkTextPrimary),
        ),
        backgroundColor: GeistColors.darkSurface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
          side: const BorderSide(color: GeistColors.darkBorder),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? GeistColors.darkSurface : GeistColors.lightSurface;
    final borderColor = isDark ? GeistColors.darkBorder : GeistColors.lightBorder;
    final primaryTextColor = isDark ? GeistColors.darkTextPrimary : GeistColors.lightTextPrimary;
    final secondaryTextColor = isDark ? GeistColors.darkTextSecondary : GeistColors.lightTextSecondary;

    return VisibilityDetector(
      key: Key('fact_visibility_${widget.factIndex}_${widget.fact.text.hashCode}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Container(
        padding: const EdgeInsets.all(GeistSpacing.xl), // Generous 32px padding
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(GeistSpacing.radiusLg),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Source Pill & Read State
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
                    '#FACT · ${widget.fact.source.toUpperCase()}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10.0),
                  ),
                ),
                if (widget.isRead)
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
            const SizedBox(height: GeistSpacing.lg),

            // Fact Text (Editorial Serif / Quote Treatment)
            Text(
              '“${widget.fact.text}”',
              style: GoogleFonts.newsreader(
                fontSize: 21.0,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                color: primaryTextColor,
                height: 1.45,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: GeistSpacing.xl),

            // Footer Actions: Bookmark & Share
            Row(
              children: [
                // Bookmark Action Button
                Semantics(
                  button: true,
                  toggled: _isBookmarked,
                  label: _isBookmarked ? 'Saved to bookmarks' : 'Save bookmark',
                  child: InkWell(
                    onTap: () => _toggleBookmark(context),
                    borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48.0, minWidth: 48.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              size: 17.0,
                              color: _isBookmarked ? GeistColors.success : secondaryTextColor,
                            ),
                            const SizedBox(width: 6.0),
                            Text(
                              _isBookmarked ? 'Saved' : 'Bookmark',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: _isBookmarked ? GeistColors.success : secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: GeistSpacing.md),

                // Share Action Button
                Semantics(
                  button: true,
                  label: 'Share fact',
                  child: InkWell(
                    onTap: () => _handleShare(context),
                    borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48.0, minWidth: 48.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_outward_rounded,
                              size: 16.0,
                              color: secondaryTextColor,
                            ),
                            const SizedBox(width: 6.0),
                            Text(
                              'Share',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
