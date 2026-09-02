import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Whether a tile should show right/wrong feedback instead of just its
/// plain selected/unselected look — used by the practice game's
/// instant-feedback mode, unused (defaults to [none]) by lesson quizzes.
enum ChoiceFeedback { none, correct, incorrect }

/// A single selectable answer choice, styled as a rounded, bordered row
/// with a circular radio indicator (matches the quiz question mockups).
class QuizChoiceTile extends StatelessWidget {
  const QuizChoiceTile({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
    this.feedback = ChoiceFeedback.none,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;
  final ChoiceFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final isCorrect = feedback == ChoiceFeedback.correct;
    final isWrong = feedback == ChoiceFeedback.incorrect;
    final accent = isCorrect
        ? AppColors.success
        : isWrong
        ? AppColors.danger
        : AppColors.primary;
    final highlighted = selected || isCorrect;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: highlighted
                ? accent.withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlighted ? accent : AppColors.border,
              width: highlighted ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: highlighted
                    ? accent.withValues(alpha: 0.15)
                    : AppColors.shadow,
                blurRadius: highlighted ? 14 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              if (feedback == ChoiceFeedback.none)
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.textMuted,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : null,
                )
              else
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect
                      ? AppColors.success
                      : (isWrong ? AppColors.danger : AppColors.textMuted),
                  size: 22,
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    fontWeight: highlighted ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
