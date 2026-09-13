import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/state/feed_provider.dart';
import '../core/theme/geist_theme.dart';
import '../widgets/cosmos_card.dart';

class CosmosScreen extends StatelessWidget {
  const CosmosScreen({super.key});

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

    final cosmosItems = feedProvider.dailyPack?.cosmos ?? [];

    if (cosmosItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_outlined, size: 36.0, color: secondaryTextColor),
            const SizedBox(height: GeistSpacing.sm),
            Text(
              'No cosmos imagery found for today',
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
        itemCount: cosmosItems.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: GeistSpacing.md),
        itemBuilder: (context, index) {
          if (index == 0) {
            final unreadCount = feedProvider.unreadCounts['cosmos'] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: GeistSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'ASTRONOMY & COSMOS',
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

          final cosmos = cosmosItems[index - 1];
          final isRead = feedProvider.seenItems.contains(cosmos.title);

          return CosmosCard(
            cosmos: cosmos,
            isRead: isRead,
            onExpand: () {
              feedProvider.markItemRead('cosmos', cosmos.title);
            },
          );
        },
      ),
    );
  }
}
