import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/models/feed_models.dart';
import '../core/state/feed_provider.dart';
import '../core/theme/geist_theme.dart';
import '../services/discovery_service.dart';
import '../widgets/article_card.dart';

class CategoryFeedScreen extends StatefulWidget {
  final String topic;
  final String topicLabel;

  const CategoryFeedScreen({
    super.key,
    required this.topic,
    required this.topicLabel,
  });

  @override
  State<CategoryFeedScreen> createState() => _CategoryFeedScreenState();
}

class _CategoryFeedScreenState extends State<CategoryFeedScreen> {
  final List<ArticleItem> _articles = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialItems();
  }

  Future<void> _loadInitialItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final feedProvider = context.read<FeedProvider>();
    final seen = feedProvider.seenItems.toList();

    try {
      final items = await DiscoveryService.instance.fetchCategory(
        topic: widget.topic,
        exclude: seen,
      );
      if (mounted) {
        setState(() {
          _articles.clear();
          _articles.addAll(items);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load category items.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoadingMore) return;
    HapticFeedback.lightImpact();

    setState(() {
      _isLoadingMore = true;
    });

    final feedProvider = context.read<FeedProvider>();
    final seen = Set<String>.from(feedProvider.seenItems)
      ..addAll(_articles.map((a) => a.title));

    try {
      final newItems = await DiscoveryService.instance.fetchCategory(
        topic: widget.topic,
        exclude: seen.toList(),
      );

      if (mounted) {
        setState(() {
          for (final item in newItems) {
            if (!_articles.any((a) => a.title == item.title)) {
              _articles.add(item);
            }
          }
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<FeedProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = GeistColors.background(isDark);
    final surfaceColor = GeistColors.cardSurface(isDark);
    final borderColor = GeistColors.border(isDark);
    final primaryTextColor = GeistColors.primaryText(isDark);
    final secondaryTextColor = GeistColors.secondaryText(isDark);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: SafeArea(
          child: Container(
            height: 60.0,
            padding: const EdgeInsets.symmetric(horizontal: GeistSpacing.sm),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(bottom: BorderSide(color: borderColor, width: 1.0)),
            ),
            child: Row(
              children: [
                // Back to Today button
                Semantics(
                  button: true,
                  label: 'Back to Today',
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(GeistSpacing.radiusLg),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48.0, minWidth: 48.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: GeistSpacing.sm,
                          vertical: GeistSpacing.xs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ExcludeSemantics(
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 14.0,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(width: GeistSpacing.xs),
                            Text(
                              'Back to Today',
                              style: TextStyle(
                                fontSize: 13.5,
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
                const Spacer(),
                // Topic Chip Header
                Semantics(
                  header: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(GeistSpacing.radiusLg),
                      border: Border.all(color: borderColor, width: 1.0),
                    ),
                    child: Text(
                      widget.topicLabel,
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        color: secondaryTextColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: SizedBox(
                width: 24.0,
                height: 24.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: primaryTextColor,
                ),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 36.0, color: secondaryTextColor),
                      const SizedBox(height: GeistSpacing.sm),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: GeistSpacing.md),
                      OutlinedButton(
                        onPressed: _loadInitialItems,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(100.0, 48.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(GeistSpacing.radiusLg),
                          ),
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: primaryTextColor,
                  backgroundColor: surfaceColor,
                  onRefresh: _loadInitialItems,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(GeistSpacing.md),
                    itemCount: _articles.length + 1,
                    separatorBuilder: (context, index) => const SizedBox(height: GeistSpacing.md),
                    itemBuilder: (context, index) {
                      // Bottom "[🎲 Load More]" button
                      if (index == _articles.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: GeistSpacing.lg),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48.0,
                            child: OutlinedButton(
                              onPressed: _isLoadingMore ? null : _loadMoreItems,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: surfaceColor,
                                side: BorderSide(color: borderColor, width: 1.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(GeistSpacing.radiusLg),
                                ),
                              ),
                              child: _isLoadingMore
                                  ? SizedBox(
                                      width: 18.0,
                                      height: 18.0,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                        color: primaryTextColor,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const ExcludeSemantics(
                                          child: Text('🎲', style: TextStyle(fontSize: 16.0)),
                                        ),
                                        const SizedBox(width: GeistSpacing.xs),
                                        Text(
                                          'Load More ${widget.topicLabel}',
                                          style: TextStyle(
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w700,
                                            color: primaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        );
                      }

                      final article = _articles[index];
                      final isRead = feedProvider.seenItems.contains(article.title);

                      return ArticleCard(
                        article: article,
                        isRead: isRead,
                        onTap: () {
                          feedProvider.markItemRead('articles', article.title);
                          ArticleReaderModal.show(context, article);
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
