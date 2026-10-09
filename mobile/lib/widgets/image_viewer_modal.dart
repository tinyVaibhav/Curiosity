import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/geist_theme.dart';
import '../core/utils/image_utils.dart';

/// Full-screen interactive pinch-to-zoom and pan image lightbox modal.
class ImageViewerModal extends StatefulWidget {
  final String imageUrl;
  final String? title;
  final String? caption;

  const ImageViewerModal({
    super.key,
    required this.imageUrl,
    this.title,
    this.caption,
  });

  /// Presents the image viewer modally with a smooth dark backdrop transition.
  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    String? title,
    String? caption,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: ImageViewerModal(
              imageUrl: imageUrl,
              title: title,
              caption: caption,
            ),
          );
        },
      ),
    );
  }

  @override
  State<ImageViewerModal> createState() => _ImageViewerModalState();
}

class _ImageViewerModalState extends State<ImageViewerModal> {
  final TransformationController _transformController = TransformationController();
  bool _showDetails = false;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = ImageUtils.resolveImageUrl(widget.imageUrl);

    return FocusScope(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Interactive Pinch-to-Zoom & Pan Canvas
            GestureDetector(
              onDoubleTap: _resetZoom,
              child: Center(
                child: InteractiveViewer(
                  transformationController: _transformController,
                  minScale: 0.8,
                  maxScale: 5.0,
                  panEnabled: true,
                  scaleEnabled: true,
                  child: Image.network(
                    resolvedUrl,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    semanticLabel: widget.title ?? 'Enlarged astronomical photograph',
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      final totalBytes = progress.expectedTotalBytes;
                      final loadedBytes = progress.cumulativeBytesLoaded;
                      final percent = totalBytes != null && totalBytes > 0
                          ? (loadedBytes / totalBytes)
                          : null;
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 32.0,
                              height: 32.0,
                              child: CircularProgressIndicator(
                                value: percent,
                                strokeWidth: 2.0,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: GeistSpacing.sm),
                            const Text(
                              'Loading high-resolution…',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.0,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.broken_image_outlined, size: 48.0, color: Colors.white54),
                            SizedBox(height: GeistSpacing.sm),
                            Text(
                              'Unable to load high-resolution image.',
                              style: TextStyle(color: Colors.white70, fontSize: 13.0),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // 2. Top Action Bar with Dismiss & Zoom Reset
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GeistSpacing.md,
                    vertical: GeistSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      // Close button
                      Semantics(
                        button: true,
                        label: 'Close full-screen image viewer',
                        child: Material(
                          color: Colors.transparent,
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26.0),
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                      const SizedBox(width: GeistSpacing.xs),
                      if (widget.title != null)
                        Expanded(
                          child: Text(
                            widget.title!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      // Zoom Reset Action
                      Semantics(
                        button: true,
                        label: 'Reset image zoom to original size',
                        child: Material(
                          color: Colors.transparent,
                          child: IconButton(
                            icon: const Icon(Icons.replay_rounded, color: Colors.white70, size: 22.0),
                            tooltip: 'Reset zoom',
                            onPressed: _resetZoom,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Bottom Information & Scientific Context Tray (if caption available)
            if (widget.caption != null && widget.caption!.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    margin: const EdgeInsets.all(GeistSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1.0,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => setState(() => _showDetails = !_showDetails),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: GeistSpacing.md,
                              vertical: GeistSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.white70,
                                  size: 16.0,
                                ),
                                const SizedBox(width: GeistSpacing.sm),
                                const Text(
                                  'Scientific Description',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  _showDetails
                                      ? Icons.keyboard_arrow_down_rounded
                                      : Icons.keyboard_arrow_up_rounded,
                                  color: Colors.white70,
                                  size: 18.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_showDetails)
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 180.0),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                GeistSpacing.md,
                                0,
                                GeistSpacing.md,
                                GeistSpacing.md,
                              ),
                              child: Text(
                                widget.caption!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.0,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
