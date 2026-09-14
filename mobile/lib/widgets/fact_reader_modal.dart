import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../core/models/feed_models.dart';
import '../core/theme/geist_theme.dart';
import '../services/discovery_service.dart';

class FactReaderModal extends StatefulWidget {
  final FactItem initialFact;

  const FactReaderModal({
    super.key,
    required this.initialFact,
  });

  static Future<void> show(BuildContext context, FactItem fact) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FactReaderModal(initialFact: fact),
    );
  }

  @override
  State<FactReaderModal> createState() => _FactReaderModalState();
}

class _FactReaderModalState extends State<FactReaderModal> {
  late FactItem _currentFact;
  bool _isBookmarked = false;
  bool _isLoadingNext = false;

  @override
  void initState() {
    super.initState();
    _currentFact = widget.initialFact;
  }

  Future<void> _rollAnotherFact() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isLoadingNext = true;
      _isBookmarked = false;
    });

    try {
      final nextFact = await DiscoveryService.instance.fetchRandomFact();
      if (mounted) {
        setState(() {
          _currentFact = nextFact;
          _isLoadingNext = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingNext = false;
        });
      }
    }
  }

  Future<void> _handleShare(BuildContext context) async {
    HapticFeedback.lightImpact();
    final shareText = '“${_currentFact.text}” — via Curiosity App';

    try {
      await SharePlus.instance.share(ShareParams(text: shareText, subject: 'Curiosity Surprise Fact'));
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: shareText));
      if (context.mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fact copied to clipboard',
              style: TextStyle(color: GeistColors.primaryText(isDark)),
            ),
            backgroundColor: GeistColors.cardSurface(isDark),
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GeistSpacing.radiusLg),
              side: BorderSide(color: GeistColors.border(isDark)),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = GeistColors.modalBackground(isDark);
    final surfaceColor = GeistColors.cardSurface(isDark);
    final primaryTextColor = GeistColors.primaryText(isDark);
    final secondaryTextColor = GeistColors.secondaryText(isDark);
    final borderColor = GeistColors.border(isDark);
    final streakColor = GeistColors.streakColor(isDark);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(GeistSpacing.radiusXl)),
        border: Border(top: BorderSide(color: borderColor, width: 1.0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  color: GeistColors.dragHandle(isDark),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
          ),

          // Scrollable fact container
          Padding(
            padding: const EdgeInsets.fromLTRB(
              GeistSpacing.xl,
              GeistSpacing.md,
              GeistSpacing.xl,
              GeistSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
                          border: Border.all(color: borderColor, width: 1.0),
                        ),
                        child: Text(
                          '#SURPRISE FACT · ${_currentFact.source.toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: GeistSpacing.sm),
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
                const SizedBox(height: GeistSpacing.lg),

                // Large Editorial Serif Quote
                Semantics(
                  liveRegion: true,
                  label: _isLoadingNext ? 'Loading next fact' : 'Fact: ${_currentFact.text}',
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _isLoadingNext
                        ? Container(
                            key: const ValueKey('loading'),
                            height: 120.0,
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: 28.0,
                              height: 28.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color: primaryTextColor,
                              ),
                            ),
                          )
                        : Text(
                            key: ValueKey(_currentFact.text),
                            '“${_currentFact.text}”',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontSize: 22.0,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w400,
                                  color: primaryTextColor,
                                  height: 1.45,
                                  letterSpacing: -0.2,
                                ),
                          ),
                  ),
                ),
                const SizedBox(height: GeistSpacing.xl),

                // Action buttons row (Bookmark, Share)
                Row(
                  children: [
                    // Bookmark Button
                    Semantics(
                      button: true,
                      toggled: _isBookmarked,
                      label: _isBookmarked ? 'Saved to bookmarks' : 'Save bookmark',
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _isBookmarked = !_isBookmarked;
                          });
                        },
                        borderRadius: BorderRadius.circular(GeistSpacing.radiusLg),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _isBookmarked
                                  ? GeistColors.bookmarkActiveBg(isDark)
                                  : surfaceColor,
                              borderRadius: BorderRadius.circular(GeistSpacing.radiusLg),
                              border: Border.all(
                                color: _isBookmarked ? streakColor : borderColor,
                                width: 1.0,
                              ),
                            ),
                            child: ExcludeSemantics(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                    size: 16.0,
                                    color: _isBookmarked ? streakColor : secondaryTextColor,
                                  ),
                                  const SizedBox(width: GeistSpacing.xs),
                                  Text(
                                    _isBookmarked ? 'Saved' : 'Bookmark',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w600,
                                      color: _isBookmarked ? streakColor : primaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: GeistSpacing.sm),

                    // Share Button
                    Semantics(
                      button: true,
                      label: 'Share fact',
                      child: InkWell(
                        onTap: () => _handleShare(context),
                        borderRadius: BorderRadius.circular(GeistSpacing.radiusLg),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(GeistSpacing.radiusLg),
                              border: Border.all(color: borderColor, width: 1.0),
                            ),
                            child: ExcludeSemantics(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.share_outlined,
                                    size: 15.0,
                                    color: secondaryTextColor,
                                  ),
                                  const SizedBox(width: GeistSpacing.xs),
                                  Text(
                                    'Share',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w600,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GeistSpacing.lg),

                // Roll Another Fact CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 48.0,
                  child: OutlinedButton.icon(
                    onPressed: _isLoadingNext ? null : _rollAnotherFact,
                    icon: const ExcludeSemantics(
                      child: Icon(Icons.casino_outlined, size: 18.0),
                    ),
                    label: const Text(
                      'Roll Another Fact',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryTextColor,
                      backgroundColor: surfaceColor,
                      side: BorderSide(color: borderColor, width: 1.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(GeistSpacing.radiusLg),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
