import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      _visibilityTimer ??= Timer(const Duration(milliseconds: 1000), () {
        if (mounted && !widget.isRead) {
          widget.onViewed();
        }
      });
    } else {
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
      await Clipboard.setData(ClipboardData(text: shareText));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Fact copied to clipboard',
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
          _isBookmarked ? 'Saved to Vault bookmarks' : 'Removed from bookmarks',
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
        padding: const EdgeInsets.all(GeistSpacing.xl),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(GeistSpacing.radiusLg),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C3136) : const Color(0xFFEDE8E1),
                      borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
                    ),
                    child: Text(
                      '#FACT · ${widget.fact.source.toUpperCase()}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10.0),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A2821) : const Color(0xFFEDF5F1),
                    borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, size: 12.0, color: isDark ? const Color(0xFF8ECBB0) : const Color(0xFF2C4E3D)),
                      const SizedBox(width: 4.0),
                      Text(
                        'VERIFIED SOURCE',
                        style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          color: isDark ? const Color(0xFF8ECBB0) : const Color(0xFF2C4E3D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: GeistSpacing.lg),

            // Body Text
            Text(
              '“${widget.fact.text}”',
              style: TextStyle(
                fontFamily: 'Lora',
                fontSize: 18.0,
                height: 1.55,
                color: primaryTextColor,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: GeistSpacing.xl),

            // Footer
            Container(
              padding: const EdgeInsets.only(top: GeistSpacing.md),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor, width: 1.0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Verified Editorial Desk',
                      style: TextStyle(
                        fontSize: 11.0,
                        fontFamily: 'monospace',
                        color: secondaryTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      // Share Button
                      Semantics(
                        button: true,
                        label: 'Share fact',
                        child: InkWell(
                          onTap: () => _handleShare(context),
                          borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 32.0, minWidth: 32.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
                                border: Border.all(color: borderColor, width: 1.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Share',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      fontFamily: 'monospace',
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4.0),
                                  Icon(
                                    Icons.arrow_outward_rounded,
                                    size: 14.0,
                                    color: secondaryTextColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: GeistSpacing.sm),

                      // Save to Vault Button
                      Semantics(
                        button: true,
                        toggled: _isBookmarked,
                        label: _isBookmarked ? 'Saved to bookmarks' : 'Save bookmark',
                        child: InkWell(
                          onTap: () => _toggleBookmark(context),
                          borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 32.0, minWidth: 32.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: _isBookmarked
                                    ? (isDark ? GeistColors.streak.withValues(alpha: 0.2) : GeistColors.streakLight.withValues(alpha: 0.1))
                                    : (isDark ? const Color(0xFF2C3136) : const Color(0xFFF2EFE9)),
                                borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
                                border: Border.all(
                                  color: _isBookmarked
                                      ? (isDark ? GeistColors.streak : GeistColors.streakLight)
                                      : Colors.transparent,
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                    size: 14.0,
                                    color: _isBookmarked
                                        ? (isDark ? GeistColors.streak : GeistColors.streakLight)
                                        : primaryTextColor,
                                  ),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    _isBookmarked ? 'Saved' : 'Save to Vault',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      fontFamily: 'monospace',
                                      color: _isBookmarked
                                          ? (isDark ? GeistColors.streak : GeistColors.streakLight)
                                          : primaryTextColor,
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
          ],
        ),
      ),
    );
  }
}
