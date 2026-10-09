import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/models/feed_models.dart';
import '../core/theme/geist_theme.dart';
import '../core/utils/image_utils.dart';
import 'image_viewer_modal.dart';

class CosmosCard extends StatefulWidget {
  final CosmosItem cosmos;
  final bool isRead;
  final VoidCallback onExpand;

  const CosmosCard({
    super.key,
    required this.cosmos,
    required this.isRead,
    required this.onExpand,
  });

  @override
  State<CosmosCard> createState() => _CosmosCardState();
}

class _CosmosCardState extends State<CosmosCard> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded && !widget.isRead) {
      widget.onExpand();
    }
  }

  void _openImageViewer(BuildContext context) {
    if (!widget.isRead) {
      widget.onExpand();
    }
    ImageViewerModal.show(
      context,
      imageUrl: widget.cosmos.url,
      title: widget.cosmos.title,
      caption: widget.cosmos.explanation,
    );
  }

  Widget _buildSkeleton(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF161616) : const Color(0xFFEEEEEE),
      child: Center(
        child: SizedBox(
          width: 24.0,
          height: 24.0,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            color: isDark ? GeistColors.darkTextSecondary : GeistColors.lightTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark, Color secondaryTextColor) {
    return Container(
      color: isDark ? const Color(0xFF24282C) : const Color(0xFFF2EFE9),
      child: Center(
        child: Icon(
          Icons.auto_awesome_outlined,
          size: 40.0,
          color: secondaryTextColor.withValues(alpha: 0.5),
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
    final canvasColor = isDark ? const Color(0xFF191C1F) : const Color(0xFFEDE8E1);
    final scrimColor = isDark ? const Color(0x99191C1F) : const Color(0x99F5F0EB);
    final resolvedUrl = ImageUtils.resolveImageUrl(widget.cosmos.url);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(GeistSpacing.radiusLg),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Edge-to-Edge Visual Focal Point with Ambient Matting & Tap-to-Zoom
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Material(
              color: canvasColor,
              child: InkWell(
                onTap: () => _openImageViewer(context),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1a. Ambient blurred background glow from image palette
                    ClipRect(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
                        child: Transform.scale(
                          scale: 1.25,
                          child: Image.network(
                            resolvedUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),

                    // 1b. Soft tinted scrim for harmonious contrast
                    Container(color: scrimColor),

                    // 1c. Foreground uncropped image (100% visible, zero cropping)
                    Image.network(
                      resolvedUrl,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      semanticLabel: 'Space photograph: ${widget.cosmos.title}',
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return _buildSkeleton(isDark);
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholder(isDark, secondaryTextColor);
                      },
                    ),

                    // Top-Left Overlay: NASA APOD
                    Positioned(
                      top: GeistSpacing.sm,
                      left: GeistSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          'NASA APOD • DEEP SKY',
                          style: TextStyle(
                            fontSize: 10.0,
                            fontFamily: 'monospace',
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ),

                    // Bottom-Left Overlay: Date or Coordinates
                    Positioned(
                      bottom: GeistSpacing.sm,
                      left: GeistSpacing.sm,
                      child: Text(
                        'JAMES WEBB NIRCam',
                        style: TextStyle(
                          fontSize: 11.0,
                          fontFamily: 'monospace',
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),

                    // 1d. Subtle "Pinch / Tap to enlarge" affordance pill
                    Positioned(
                      right: GeistSpacing.sm,
                      bottom: GeistSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.fullscreen_rounded, size: 14.0, color: Colors.white),
                            SizedBox(width: 4.0),
                            Text(
                              'Zoom',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Editorial Metadata & Header Block (cleanly separated below photo)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              GeistSpacing.md,
              GeistSpacing.md,
              GeistSpacing.md,
              GeistSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isRead) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: GeistColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
                      border: Border.all(
                        color: GeistColors.success.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_rounded, size: 12.0, color: GeistColors.success),
                        SizedBox(width: 3.0),
                        Text(
                          'Read',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: GeistColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: GeistSpacing.sm),
                ],
                Semantics(
                  header: true,
                  child: Text(
                    widget.cosmos.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 17.0,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                          letterSpacing: -0.3,
                          height: 1.3,
                        ),
                  ),
                ),
              ],
            ),
          ),

          // 3. The Astronomer's Notes - Accordion Trigger
          Semantics(
            button: true,
            expanded: _isExpanded,
            label: _isExpanded ? 'Collapse Scientific Breakdown' : 'Read Scientific Breakdown',
            child: InkWell(
              onTap: _toggleExpanded,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GeistSpacing.md,
                    vertical: GeistSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          _isExpanded ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded,
                          size: 16.0,
                          color: isDark ? GeistColors.accent : GeistColors.accentLight,
                        ),
                      ),
                      const SizedBox(width: GeistSpacing.sm),
                      Text(
                        _isExpanded ? 'Collapse Scientific Breakdown' : 'Read Scientific Breakdown',
                        style: TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const Spacer(),
                      ExcludeSemantics(
                        child: Icon(
                          _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 18.0,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Smooth In-Place Accordion Content
          AnimatedCrossFade(
            duration: GeistMotion.durationStandard,
            firstCurve: GeistMotion.springCurve,
            secondCurve: GeistMotion.springCurve,
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding: const EdgeInsets.fromLTRB(
                GeistSpacing.md,
                0,
                GeistSpacing.md,
                GeistSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: borderColor, height: 1.0),
                  const SizedBox(height: GeistSpacing.sm),
                  Text(
                    widget.cosmos.explanation,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: secondaryTextColor,
                          height: 1.5,
                          fontSize: 13.5,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
