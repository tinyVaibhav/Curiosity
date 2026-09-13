import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/state/feed_provider.dart';
import '../core/theme/geist_theme.dart';
import '../widgets/article_card.dart';

class ArticlesScreen extends StatelessWidget {
  const ArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<FeedProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? GeistColors.darkTextPrimary : GeistColors.lightTextPrimary;
    final secondaryTextColor = isDark ? GeistColors.darkTextSecondary : GeistColors.lightTextSecondary;

    if (feedProvider.isLoading && feedProvider.dailyPack == null) {
      return Center(
        child: SizedBox(
          width: 24.0,
          height: 24.0,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            color: primaryTextColor,
          ),
        ),
      );
    }

    final articles = feedProvider.dailyPack?.articles ?? [];

    if (articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 36.0, color: secondaryTextColor),
            const SizedBox(height: GeistSpacing.sm),
            Text(
              'No articles found for today',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: primaryTextColor),
            ),
            const SizedBox(height: GeistSpacing.xs),
            Text(
              'Pull down to refresh and fetch the daily feed.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: secondaryTextColor),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: primaryTextColor,
      backgroundColor: isDark ? GeistColors.darkSurface : GeistColors.lightSurface,
      onRefresh: () => feedProvider.fetchDailyFeed(),
      child: ListView.separated(
        padding: const EdgeInsets.all(GeistSpacing.md),
        itemCount: articles.length + 1, // +1 for header or completed banner
        separatorBuilder: (context, index) => const SizedBox(height: GeistSpacing.md),
        itemBuilder: (context, index) {
          if (index == 0) {
            // Header summary row
            final unreadCount = feedProvider.unreadCounts['articles'] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: GeistSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'DAILY DEEP DIVES',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: secondaryTextColor,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ),
                  Text(
                    unreadCount == 0 ? 'Inbox Zero ✓' : '$unreadCount unread',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w700,
                      color: unreadCount == 0 ? GeistColors.success : secondaryTextColor,
                    ),
                  ),
                ],
              ),
            );
          }

          final article = articles[index - 1];
          final isRead = feedProvider.seenItems.contains(article.title);

          return ArticleCard(
            article: article,
            isRead: isRead,
            onTap: () {
              // Decrement badge & mark read
              feedProvider.markItemRead('articles', article.title);
              // Open modal reader
              ArticleReaderModal.show(context, article);
            },
          );
        },
      ),
    );
  }
}
