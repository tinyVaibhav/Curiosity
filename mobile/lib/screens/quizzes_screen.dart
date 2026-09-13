import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/state/feed_provider.dart';
import '../core/theme/geist_theme.dart';
import '../widgets/quiz_card.dart';

class QuizzesScreen extends StatelessWidget {
  const QuizzesScreen({super.key});

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

    final quizzes = feedProvider.dailyPack?.quizzes ?? [];

    if (quizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology_outlined, size: 36.0, color: secondaryTextColor),
            const SizedBox(height: GeistSpacing.sm),
            Text(
              'No quizzes available for today',
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
        itemCount: quizzes.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: GeistSpacing.md),
        itemBuilder: (context, index) {
          if (index == 0) {
            final unreadCount = feedProvider.unreadCounts['quizzes'] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: GeistSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'DAILY TRIVIA QUIZZES',
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

          final quiz = quizzes[index - 1];
          final isRead = feedProvider.seenItems.contains(quiz.question);

          return QuizCard(
            quiz: quiz,
            questionIndex: index,
            totalQuestions: quizzes.length,
            isRead: isRead,
            onAnswered: () {
              feedProvider.markItemRead('quizzes', quiz.question);
            },
          );
        },
      ),
    );
  }
}
