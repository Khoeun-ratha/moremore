import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/api_error.dart';
import '../../api/api_services.dart';
import '../../l10n/l10n_extension.dart';
import '../../models/lesson.dart';
import '../../models/progress.dart';
import '../../models/quiz.dart';
import '../../theme/app_theme.dart';
import '../../utils/media.dart';
import '../../utils/youtube.dart';
import '../../widgets/error_view.dart';
import '../../widgets/lesson_video_player.dart';
import '../../widgets/youtube_lesson_player.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.lessonId});

  final int lessonId;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  Lesson? _lesson;
  List<QuizAttempt>? _attempts;
  CourseProgress? _courseProgress;
  bool _loading = true;
  bool _completing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiServices>();
      final lesson = await api.lessons.get(widget.lessonId);
      Quiz? quiz;
      List<QuizAttempt> attempts = const [];
      if (lesson.hasQuiz) {
        try {
          quiz = await api.lessons.getQuiz(widget.lessonId);
          attempts = await api.lessons.getAttempts(quiz.id);
        } catch (_) {
          // Best-effort: the quiz/attempt history isn't essential to viewing the lesson.
        }
      }
      CourseProgress? courseProgress;
      try {
        courseProgress = await api.progress.forCourse(lesson.courseId);
      } catch (_) {
        // Best-effort: only used for the "x/y lessons" progress pill.
      }
      setState(() {
        _lesson = lesson;
        _attempts = attempts;
        _courseProgress = courseProgress;
      });
    } catch (e) {
      if (mounted) setState(() => _error = extractErrorMessage(context, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markComplete() async {
    setState(() => _completing = true);
    try {
      final updated = await context.read<ApiServices>().lessons.markComplete(
        widget.lessonId,
      );
      if (mounted) setState(() => _lesson = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(extractErrorMessage(context, e))),
        );
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trRead('couldNotOpenFile'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _courseProgress;
    return Scaffold(
      appBar: AppBar(
        title: Text(_lesson?.title ?? ''),
        actions: [
          if (progress != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${progress.completedLessons}/${progress.totalLessons}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
        bottom: progress == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: SizedBox(
                  height: 3,
                  child: LinearProgressIndicator(
                    value: (progress.percentage / 100).clamp(0, 1),
                    minHeight: 3,
                    backgroundColor: AppColors.border,
                    color: AppColors.primary,
                  ),
                ),
              ),
      ),
      body: AnimatedSwitcher(
        duration: AppMotion.fast,
        switchInCurve: AppMotion.curve,
        switchOutCurve: AppMotion.curve,
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    final tr = context.tr;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    final lesson = _lesson!;
    final videoUrl = lesson.videoUrl;
    final fileUrl = lesson.fileUrl;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (videoUrl != null && videoUrl.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: isYoutubeUrl(videoUrl)
                  ? YoutubeLessonPlayer(url: videoUrl)
                  : LessonVideoPlayer(url: mediaUrl(videoUrl)),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tr('lessonNumberBadge', {'n': lesson.orderIndex + 1}),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.primaryHigh,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          lesson.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (lesson.content.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            tr('aboutThisLesson'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                lesson.content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
        if (fileUrl != null && fileUrl.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            tr('resources'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: AppColors.primaryHigh,
                  size: 20,
                ),
              ),
              title: Text(tr('lessonSlidesResource')),
              subtitle: Text(tr('tapToOpenFile')),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _openFile(mediaUrl(fileUrl)),
            ),
          ),
        ],
        if (_attempts != null && _attempts!.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text(
            tr('yourAttempts'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: List.generate(_attempts!.length, (i) {
                final attempt = _attempts![i];
                return Column(
                  children: [
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        attempt.passed ? Icons.check_circle : Icons.cancel,
                        color: attempt.passed
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                      title: Text(
                        tr('correctCount', {
                          'score': attempt.score,
                          'total': attempt.total,
                        }),
                      ),
                      subtitle: Text(
                        DateFormat.yMMMd().add_jm().format(
                          attempt.submittedAt.toLocal(),
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => context.push('/quiz-attempts/${attempt.id}'),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ],
    );
  }

  Widget? _buildBottomBar() {
    final tr = context.tr;
    final lesson = _lesson;
    if (lesson == null) return null;

    late final Widget content;
    if (lesson.hasQuiz) {
      content = Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lesson.completed
                      ? tr('quizPassed')
                      : tr('thisLessonIncludesQuiz'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lesson.completed
                      ? tr('retakeAnytimeHint')
                      : tr('passWithRequiredScore'),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
            onPressed: () => context.push('/lessons/${lesson.id}/quiz'),
            icon: Icon(
              lesson.completed ? Icons.replay : Icons.quiz_outlined,
              size: 18,
            ),
            label: Text(lesson.completed ? tr('retake') : tr('takeTheQuiz')),
          ),
        ],
      );
    } else if (lesson.completed) {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
          const SizedBox(width: 8),
          Text(
            tr('lessonCompleted'),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      );
    } else {
      content = SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _completing ? null : _markComplete,
          icon: _completing
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle_outline),
          label: Text(tr('markAsComplete')),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(top: false, child: content),
    );
  }
}
