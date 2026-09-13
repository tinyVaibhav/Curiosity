import 'package:flutter/material.dart';
import '../core/models/feed_models.dart';
import '../core/theme/geist_theme.dart';
import '../core/utils/image_utils.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? GeistColors.darkSurface : GeistColors.lightSurface;
    final borderColor = isDark ? GeistColors.darkBorder : GeistColors.lightBorder;
    final primaryTextColor = isDark ? GeistColors.darkTextPrimary : GeistColors.lightTextPrimary;
    final secondaryTextColor = isDark ? GeistColors.darkTextSecondary : GeistColors.lightTextSecondary;

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
          // 1. Edge-to-Edge Visual Focal Point with Gradient Text Overlay
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Space Photograph
                Image.network(
                  ImageUtils.resolveImageUrl(widget.cosmos.url),
                  semanticLabel: 'Space photograph: ${widget.cosmos.title}',
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: isDark ? const Color(0xFF161616) : const Color(0xFFEEEEEE),
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
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: isDark ? const Color(0xFF161616) : const Color(0xFFEEEEEE),
                      child: Center(
                        child: Icon(
                          Icons.auto_awesome_outlined,
                          size: 40.0,
                          color: secondaryTextColor.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  },
                ),

                // Smooth Dark Linear Gradient (to-top from black to transparent)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.92),
                          Colors.black.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 0.85],
                      ),
                    ),
                  ),
                ),

                // Overlay Text: Category Tag, Title, and Read Badge
                Positioned(
                  left: GeistSpacing.md,
                  right: GeistSpacing.md,
                  bottom: GeistSpacing.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.8),
                            ),
                            child: const Text(
                              '#COSMOS · NASA APOD',
                              style: TextStyle(
                                fontSize: 10.0,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (widget.isRead)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
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
                        ],
                      ),
                      const SizedBox(height: GeistSpacing.xs),
                      Text(
                        widget.cosmos.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. The Astronomer's Notes - Accordion Trigger
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
                          color: primaryTextColor,
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

          // 3. Smooth In-Place Accordion Content
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            firstCurve: Curves.easeInOut,
            secondCurve: Curves.easeInOut,
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
                  const Divider(color: GeistColors.darkBorder, height: 1.0),
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
