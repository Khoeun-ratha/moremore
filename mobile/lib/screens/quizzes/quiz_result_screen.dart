import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../api/api_error.dart';
import '../../api/api_services.dart';
import '../../models/certificate.dart';
import '../../models/quiz.dart';
import '../../theme/app_theme.dart';
import '../../widgets/score_gauge.dart';
import '../../widgets/stat_tile.dart';

/// Bundles a freshly-submitted [QuizResult] with the course it belongs to,
/// so the result screen can figure out what "Continue" should do next
/// (open the next lesson, or celebrate a finished course) instead of just
/// dumping the learner back on the course list.
class QuizResultArgs {
  QuizResultArgs({required this.result, required this.courseId});

  final QuizResult result;
  final int courseId;
}

class QuizResultScreen extends StatefulWidget {
  const QuizResultScreen({
    super.key,
    required this.result,
    this.courseId,
    this.isHistorical = false,
  });

  final QuizResult result;

  /// The course this quiz's lesson belongs to. Only known right after a
  /// live submission (via [QuizResultArgs]) — null when reviewing history,
  /// where "Continue" isn't offered.
  final int? courseId;

  /// True when this is opened from "Your attempts" on the lesson screen to
  /// review a past submission, rather than shown right after submitting.
  final bool isHistorical;

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  bool _continuing = false;

  Future<void> _continue() async {
    final courseId = widget.courseId;
    if (courseId == null) {
      context.go('/courses');
      return;
    }
    setState(() => _continuing = true);
    try {
      final api = context.read<ApiServices>();
      final lessons = await api.lessons.listForCourse(courseId);
      final remaining = lessons.where((l) => !l.completed).toList();
      if (!mounted) return;

      if (remaining.isNotEmpty) {
        context.go('/lessons/${remaining.first.id}');
        return;
      }

      // No lessons left incomplete: the course is finished, so look up the
      // certificate that `mark_lesson_complete` auto-issues and celebrate it.
      final certificates = await api.certificates.me();
      Certificate? certificate;
      for (final c in certificates) {
        if (c.courseId == courseId) {
          certificate = c;
          break;
        }
      }
      if (!mounted) return;
      if (certificate != null) {
        context.go('/certificate-celebration', extra: certificate);
      } else {
        context.go('/courses/$courseId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(extractErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _continuing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final passed = result.passed;
    final canContinue = !widget.isHistorical && widget.courseId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isHistorical ? 'Attempt Details' : 'Quiz Results'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () =>
                widget.isHistorical ? context.pop() : context.go('/courses'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (passed ? AppColors.success : AppColors.danger)
                      .withValues(alpha: 0.06),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ScoreGauge(
                      percentage: result.percentage,
                      colors: passed
                          ? const [AppColors.success, AppColors.primary]
                          : const [AppColors.danger, AppColors.warning],
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: passed ? AppColors.success : AppColors.danger,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          passed ? Icons.check : Icons.close,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                passed ? 'Great job!' : 'Keep Practicing',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                passed
                    ? "You've successfully completed this quiz."
                    : 'Review your answers below and try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Score',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${result.score}/${result.total} Correct',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (result.percentage / 100).clamp(0, 1),
                  minHeight: 8,
                ),
              ),
              if (passed && canContinue) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: AppColors.success,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Lesson marked complete',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      icon: Icons.check_circle_outline,
                      iconColor: AppColors.success,
                      value: '${result.score}',
                      label: 'CORRECT',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      icon: passed
                          ? Icons.emoji_events_outlined
                          : Icons.refresh,
                      iconColor: passed ? AppColors.warning : AppColors.danger,
                      value: passed ? 'Passed' : 'Retry',
                      label: 'RESULT',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Review Answers',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: List.generate(result.answers.length, (i) {
                      final answer = result.answers[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              answer.isCorrect
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: answer.isCorrect
                                  ? AppColors.success
                                  : AppColors.danger,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Question ${i + 1}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              if (widget.isHistorical)
                OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Close'),
                )
              else ...[
                if (passed)
                  FilledButton.icon(
                    onPressed: _continuing ? null : _continue,
                    icon: _continuing
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.arrow_forward, size: 18),
                    label: Text(
                      canContinue
                          ? 'Continue to Next Lesson'
                          : 'Back to Courses',
                    ),
                  )
                else
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('Retake Quiz'),
                  ),
                if (!passed || canContinue) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.go('/courses'),
                    child: const Text('Back to Courses'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
