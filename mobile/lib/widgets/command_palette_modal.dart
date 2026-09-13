import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/models/feed_models.dart';
import '../core/theme/geist_theme.dart';
import '../core/utils/image_utils.dart';
import '../core/utils/text_utils.dart';
import '../screens/category_feed_screen.dart';
import '../services/discovery_service.dart';
import 'article_card.dart';
import 'fact_reader_modal.dart';

class CommandPaletteModal extends StatefulWidget {
  const CommandPaletteModal({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Command Palette',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const CommandPaletteModal();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<CommandPaletteModal> createState() => _CommandPaletteModalState();
}

class _CommandPaletteModalState extends State<CommandPaletteModal> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounceTimer;
  bool _isSearching = false;
  bool _isLoadingSurpriseArticle = false;
  bool _isLoadingSurpriseFact = false;
  String _currentQuery = '';
  List<ArticleItem> _searchResults = [];

  static const List<Map<String, String>> _categories = [
    {'topic': 'SPACE', 'label': '🚀 Space & Physics'},
    {'topic': 'HISTORY', 'label': '🏛️ Ancient History'},
    {'topic': 'BIOLOGY', 'label': '🧬 Biology & Nature'},
    {'topic': 'TECH', 'label': '💻 Tech & Logic'},
  ];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final trimmed = query.trim();
    if (trimmed == _currentQuery) return;

    _debounceTimer?.cancel();
    setState(() {
      _currentQuery = trimmed;
    });

    if (trimmed.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // 300ms debounce
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final results = await DiscoveryService.instance.search(trimmed);
      if (mounted && _currentQuery == trimmed) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _handleSurpriseArticle() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isLoadingSurpriseArticle = true;
    });

    try {
      final article = await DiscoveryService.instance.fetchRandomArticle();
      if (!mounted) return;
      Navigator.of(context).pop();
      ArticleReaderModal.show(context, article);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingSurpriseArticle = false;
        });
      }
    }
  }

  Future<void> _handleSurpriseFact() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isLoadingSurpriseFact = true;
    });

    try {
      final fact = await DiscoveryService.instance.fetchRandomFact();
      if (!mounted) return;
      Navigator.of(context).pop();
      FactReaderModal.show(context, fact);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingSurpriseFact = false;
        });
      }
    }
  }

  void _onCategoryTapped(BuildContext context, String topic, String label) {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryFeedScreen(topic: topic, topicLabel: label),
      ),
    );
  }

  void _onSearchResultTapped(BuildContext context, ArticleItem article) {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    ArticleReaderModal.show(context, article);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? GeistColors.darkSurface : GeistColors.lightSurface;
    final borderColor = isDark ? GeistColors.darkBorder : GeistColors.lightBorder;
    final primaryTextColor = isDark ? GeistColors.darkTextPrimary : GeistColors.lightTextPrimary;
    final secondaryTextColor = isDark ? GeistColors.darkTextSecondary : GeistColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GeistSpacing.lg,
              vertical: GeistSpacing.md,
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 580, maxHeight: 600),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(GeistSpacing.radiusLg),
                border: Border.all(color: borderColor, width: 1.0),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Search Header ---
                  Container(
                    height: 56.0,
                    padding: const EdgeInsets.symmetric(horizontal: GeistSpacing.md),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: borderColor, width: 1.0)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 20.0,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: GeistSpacing.sm),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            autofocus: false, // CRITICAL UX: Prevent abrupt keyboard shifts
                            onChanged: _onSearchChanged,
                            style: TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w400,
                              color: primaryTextColor,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search topics…',
                              hintStyle: TextStyle(
                                fontSize: 15.0,
                                color: secondaryTextColor,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_currentQuery.isNotEmpty)
                          IconButton(
                            tooltip: 'Clear search query',
                            icon: const Icon(Icons.clear_rounded, size: 18.0),
                            color: secondaryTextColor,
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          ),
                        const SizedBox(width: GeistSpacing.xs),
                        // Close / ESC pill
                        Semantics(
                          button: true,
                          label: 'Close search palette',
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(4.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 3.0),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF222222) : const Color(0xFFE5E5E5),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                'ESC',
                                style: TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hairline Loading Bar when searching
                  if (_isSearching)
                    LinearProgressIndicator(
                      minHeight: 2.0,
                      backgroundColor: surfaceColor,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryTextColor),
                    ),

                  // --- Content Body (Animated Switcher between Initial and Search) ---
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _currentQuery.isEmpty
                          ? _buildInitialState(context, isDark, primaryTextColor, secondaryTextColor, borderColor, surfaceColor)
                          : _buildSearchResultsState(context, isDark, primaryTextColor, secondaryTextColor, borderColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Initial State (Quick-Roll Triggers & Category Grid) ---
  Widget _buildInitialState(
    BuildContext context,
    bool isDark,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color borderColor,
    Color surfaceColor,
  ) {
    return SingleChildScrollView(
      key: const ValueKey('initial_state'),
      padding: const EdgeInsets.all(GeistSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Quick Roll (Surprise Article + Surprise Fact)
          Semantics(
            header: true,
            child: Text(
              'SERENDIPITY',
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: secondaryTextColor,
              ),
            ),
          ),
          const SizedBox(height: GeistSpacing.sm),

          Row(
            children: [
              // Surprise Article Button
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoadingSurpriseArticle ? null : _handleSurpriseArticle,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF161616) : const Color(0xFFF9F9F9),
                    side: BorderSide(color: borderColor, width: 1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: GeistSpacing.md, horizontal: GeistSpacing.xs),
                  ),
                  child: _isLoadingSurpriseArticle
                      ? SizedBox(
                          width: 16.0,
                          height: 16.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0, color: primaryTextColor),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const ExcludeSemantics(
                              child: Text('🎲', style: TextStyle(fontSize: 14.0)),
                            ),
                            const SizedBox(width: 4.0),
                            Flexible(
                              child: Text(
                                'Surprise Article',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w700,
                                  color: primaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(width: GeistSpacing.sm),

              // Surprise Fact Button
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoadingSurpriseFact ? null : _handleSurpriseFact,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF161616) : const Color(0xFFF9F9F9),
                    side: BorderSide(color: borderColor, width: 1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: GeistSpacing.md, horizontal: GeistSpacing.xs),
                  ),
                  child: _isLoadingSurpriseFact
                      ? SizedBox(
                          width: 16.0,
                          height: 16.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0, color: primaryTextColor),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const ExcludeSemantics(
                              child: Text('⚡', style: TextStyle(fontSize: 14.0)),
                            ),
                            const SizedBox(width: 4.0),
                            Flexible(
                              child: Text(
                                'Surprise Fact',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w700,
                                  color: primaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: GeistSpacing.xl),

          // Section 2: Explore Seed Categories
          Semantics(
            header: true,
            child: Text(
              'EXPLORE TOPICS',
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: secondaryTextColor,
              ),
            ),
          ),
          const SizedBox(height: GeistSpacing.sm),

          Wrap(
            spacing: GeistSpacing.sm,
            runSpacing: GeistSpacing.sm,
            children: _categories.map((cat) {
              final topic = cat['topic']!;
              final label = cat['label']!;
              return InkWell(
                onTap: () => _onCategoryTapped(context, topic, label),
                borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161616) : const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
                      border: Border.all(color: borderColor, width: 1.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(width: GeistSpacing.xs),
                        ExcludeSemantics(
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11.0,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- Search Results State (ListView with Thumbnails) ---
  Widget _buildSearchResultsState(
    BuildContext context,
    bool isDark,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    if (!_isSearching && _searchResults.isEmpty) {
      return Center(
        key: const ValueKey('empty_search'),
        child: Padding(
          padding: const EdgeInsets.all(GeistSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 36.0, color: secondaryTextColor),
              const SizedBox(height: GeistSpacing.sm),
              Text(
                'No Results Found.',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      key: const ValueKey('results_list'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(vertical: GeistSpacing.sm),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => Divider(height: 1.0, color: borderColor),
      itemBuilder: (context, index) {
        final article = _searchResults[index];
        final cleanTitle = TextUtils.cleanWikiTitle(
          article.normalizedTitle.isNotEmpty ? article.normalizedTitle : article.title,
        );

        return InkWell(
          onTap: () => _onSearchResultTapped(context, article),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GeistSpacing.md,
              vertical: GeistSpacing.sm,
            ),
            child: Row(
              children: [
                // Leading thumbnail or icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
                  child: Container(
                    width: 44.0,
                    height: 44.0,
                    color: isDark ? const Color(0xFF222222) : const Color(0xFFE5E5E5),
                    child: (article.thumbnailUrl != null && article.thumbnailUrl!.isNotEmpty)
                        ? Image.network(
                            ImageUtils.resolveImageUrl(article.thumbnailUrl!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.article_outlined,
                              size: 22.0,
                              color: secondaryTextColor,
                            ),
                          )
                        : Icon(
                            Icons.article_outlined,
                            size: 22.0,
                            color: secondaryTextColor,
                          ),
                  ),
                ),
                const SizedBox(width: GeistSpacing.md),

                // Title and Clamped extract
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cleanTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        article.summary,
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
                const SizedBox(width: GeistSpacing.sm),
                Icon(
                  Icons.arrow_outward_rounded,
                  size: 16.0,
                  color: secondaryTextColor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
