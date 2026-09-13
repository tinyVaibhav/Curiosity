import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/models/feed_models.dart';
import '../core/theme/geist_theme.dart';

class QuizCard extends StatefulWidget {
  final QuizItem quiz;
  final int questionIndex;
  final int totalQuestions;
  final bool isRead;
  final VoidCallback onAnswered;

  const QuizCard({
    super.key,
    required this.quiz,
    required this.questionIndex,
    required this.totalQuestions,
    required this.isRead,
    required this.onAnswered,
  });

  @override
  State<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<QuizCard> {
  late List<String> _shuffledOptions;
  String? _selectedOption;
  bool _hasAnswered = false;

  @override
  void initState() {
    super.initState();
    // Combine and deterministically shuffle options based on question seed
    _shuffledOptions = [widget.quiz.correctAnswer, ...widget.quiz.incorrectAnswers];
    final seed = widget.quiz.question.hashCode;
    _shuffledOptions.shuffle(Random(seed));
  }

  void _handleOptionSelected(String option) {
    if (_hasAnswered) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _selectedOption = option;
      _hasAnswered = true;
    });

    // Notify provider to decrement badge
    widget.onAnswered();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? GeistColors.darkSurface : GeistColors.lightSurface;
    final borderColor = isDark ? GeistColors.darkBorder : GeistColors.lightBorder;
    final primaryTextColor = isDark ? GeistColors.darkTextPrimary : GeistColors.lightTextPrimary;
    final secondaryTextColor = isDark ? GeistColors.darkTextSecondary : GeistColors.lightTextSecondary;

    final isCorrect = _selectedOption == widget.quiz.correctAnswer;

    return Container(
      padding: const EdgeInsets.all(GeistSpacing.lg),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(GeistSpacing.radiusLg),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Category Pill, Counter, and Read Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(GeistSpacing.radiusSm),
                    ),
                    child: Text(
                      '#QUIZ',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10.0),
                    ),
                  ),
                  const SizedBox(width: GeistSpacing.sm),
                  Text(
                    '${widget.questionIndex} OF ${widget.totalQuestions}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: secondaryTextColor,
                          fontSize: 10.5,
                        ),
                  ),
                ],
              ),
              if (_hasAnswered || widget.isRead)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_rounded, size: 14.0, color: GeistColors.success),
                    SizedBox(width: 3.0),
                    Text(
                      'Answered',
                      style: TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        color: GeistColors.success,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: GeistSpacing.md),

          // Question Text
          Text(
            widget.quiz.question,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 19.0,
                  color: primaryTextColor,
                  height: 1.3,
                ),
          ),
          const SizedBox(height: GeistSpacing.lg),

          // Options List (4 Full-Width Buttons)
          ..._shuffledOptions.map((option) {
            return _buildOptionButton(
              context: context,
              option: option,
              isDark: isDark,
              primaryTextColor: primaryTextColor,
            );
          }),

          // Post-Answer Explanation Box
          if (_hasAnswered) ...[
            const SizedBox(height: GeistSpacing.md),
            Semantics(
              liveRegion: true,
              container: true,
              label: isCorrect
                  ? 'Correct answer! Spot on! The verified answer is ${widget.quiz.correctAnswer}.'
                  : 'Incorrect. The correct answer is ${widget.quiz.correctAnswer}.',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(GeistSpacing.md),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? const Color(0xFF052e16).withValues(alpha: isDark ? 0.7 : 0.15)
                      : const Color(0xFF450a0a).withValues(alpha: isDark ? 0.7 : 0.15),
                  borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
                  border: Border.all(
                    color: isCorrect ? const Color(0xFF22c55e) : const Color(0xFFef4444),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle_outline_rounded : Icons.highlight_off_rounded,
                      size: 20.0,
                      color: isCorrect ? const Color(0xFF22c55e) : const Color(0xFFef4444),
                    ),
                    const SizedBox(width: GeistSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCorrect ? 'Correct!' : 'Incorrect',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? (isCorrect ? const Color(0xFF22c55e) : const Color(0xFFef4444))
                                  : (isCorrect ? GeistColors.successTextLight : GeistColors.errorTextLight),
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            isCorrect
                                ? 'Spot on! The verified answer is "${widget.quiz.correctAnswer}".'
                                : 'The correct answer is "${widget.quiz.correctAnswer}".',
                            style: TextStyle(
                              fontSize: 13.0,
                              color: primaryTextColor,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required String option,
    required bool isDark,
    required Color primaryTextColor,
  }) {
    Color buttonBackground;
    Color buttonBorder;
    Color textColor = primaryTextColor;

    if (!_hasAnswered) {
      // Default state
      buttonBackground = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF2F2F2);
      buttonBorder = isDark ? const Color(0xFF333333) : const Color(0xFFDDDDDD);
    } else {
      final isSelected = _selectedOption == option;
      final isCorrectAnswer = option == widget.quiz.correctAnswer;

      if (isSelected && isCorrectAnswer) {
        // Tapped correctly
        buttonBackground = const Color(0xFF052e16);
        buttonBorder = const Color(0xFF22c55e);
        textColor = const Color(0xFFbbf7d0);
      } else if (isSelected && !isCorrectAnswer) {
        // Tapped incorrectly
        buttonBackground = const Color(0xFF450a0a);
        buttonBorder = const Color(0xFFef4444);
        textColor = const Color(0xFFfecaca);
      } else if (isCorrectAnswer) {
        // Highlight actual answer in green
        buttonBackground = const Color(0xFF052e16).withValues(alpha: 0.6);
        buttonBorder = const Color(0xFF22c55e);
        textColor = const Color(0xFFbbf7d0);
      } else {
        // Other non-selected options
        buttonBackground = isDark ? const Color(0xFF141414) : const Color(0xFFF5F5F5);
        buttonBorder = isDark ? const Color(0xFF242424) : const Color(0xFFE5E5E5);
        textColor = isDark ? GeistColors.darkTextTertiary : GeistColors.lightTextTertiary;
      }
    }

    final semanticLabel = _hasAnswered
        ? (option == widget.quiz.correctAnswer
            ? '$option, correct answer'
            : (_selectedOption == option ? '$option, selected incorrect answer' : option))
        : option;

    return Padding(
      padding: const EdgeInsets.only(bottom: GeistSpacing.sm),
      child: Semantics(
        button: true,
        enabled: !_hasAnswered,
        selected: _selectedOption == option,
        label: semanticLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _hasAnswered ? null : () => _handleOptionSelected(option),
            borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: GeistSpacing.md,
                  vertical: 13.0,
                ),
                decoration: BoxDecoration(
                  color: buttonBackground,
                  borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
                  border: Border.all(color: buttonBorder, width: 1.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                          color: textColor,
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (_hasAnswered && option == widget.quiz.correctAnswer)
                      const ExcludeSemantics(
                        child: Icon(Icons.check_circle_rounded, size: 18.0, color: Color(0xFF22c55e)),
                      )
                    else if (_hasAnswered && _selectedOption == option)
                      const ExcludeSemantics(
                        child: Icon(Icons.cancel_rounded, size: 18.0, color: Color(0xFFef4444)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
