import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../api/api_error.dart';
import '../../api/api_services.dart';
import '../../l10n/l10n_extension.dart';
import '../../models/certificate.dart';
import '../../models/course.dart';
import '../../models/lesson.dart';
import '../../models/progress.dart';
import '../../models/review.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_view.dart';
import '../../widgets/game_entry_card.dart';

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final int courseId;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  CourseDetail? _course;
  List<Lesson>? _lessons;
  CourseProgress? _progress;
  List<Review>? _reviews;
  bool _loading = true;
  String? _error;
  bool _showCompletedLessons = false;
  bool _loadingCertificate = false;

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
      final results = await Future.wait([
        api.courses.get(widget.courseId),
        api.lessons.listForCourse(widget.courseId),
        api.progress.forCourse(widget.courseId),
        api.courses.getReviews(widget.courseId),
      ]);
      setState(() {
        _course = results[0] as CourseDetail;
        _lessons = results[1] as List<Lesson>;
        _progress = results[2] as CourseProgress;
        _reviews = results[3] as List<Review>;
      });
    } catch (e) {
      if (mounted) setState(() => _error = extractErrorMessage(context, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> _ratingLabels(String Function(String) tr) => [
    tr('ratingPoor'),
    tr('ratingFair'),
    tr('ratingGood'),
    tr('ratingVeryGood'),
    tr('ratingExcellent'),
  ];

  Future<void> _openReviewDialog() async {
    final tr = context.trRead;
    final ratingLabels = _ratingLabels(tr);
    final course = _course!;
    var rating = 5;
    final commentController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          title: Text(
            tr('rateThisCourse'),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (i) {
                  final starValue = i + 1;
                  return GestureDetector(
                    onTap: () => setDialogState(() => rating = starValue),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        starValue <= rating ? Icons.star : Icons.star_border,
                        size: 32,
                        color: Colors.amber,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),
              Text(
                ratingLabels[rating - 1],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: tr('shareYourThoughts'),
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceHigh,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(tr('cancel')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(tr('submit')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (submitted != true || !mounted) return;
    try {
      await context.read<ApiServices>().courses.submitReview(
        course.id,
        rating: rating,
        comment: commentController.text.trim(),
      );
      if (mounted) _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(extractErrorMessage(context, e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_course?.title ?? ''),
          bottom: _loading || _error != null
              ? null
              : TabBar(
                  tabs: [
                    Tab(text: tr('lessonsTab')),
                    Tab(text: tr('reviewsTab')),
                  ],
                ),
        ),
        body: AnimatedSwitcher(
          duration: AppMotion.fast,
          switchInCurve: AppMotion.curve,
          switchOutCurve: AppMotion.curve,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    return TabBarView(children: [_buildLessonsTab(), _buildReviewsTab()]);
  }

  Widget _buildLessonsTab() {
    final course = _course!;
    final lessons = _lessons!;
    final progress = _progress!;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              if (course.category.isNotEmpty) ...[
                _badge(
                  course.category,
                  background: AppColors.primary.withValues(alpha: 0.15),
                  foreground: AppColors.primaryHigh,
                ),
                const SizedBox(width: 8),
              ],
              _badge(
                course.level,
                background: AppColors.surfaceHigh,
                foreground: AppColors.textSecondary,
              ),
              const Spacer(),
              if (course.averageRating != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 15, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        course.averageRating!.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '(${course.reviewCount})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            course.description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _buildProgressCard(progress),
          const SizedBox(height: 16),
          GameEntryCard(
            title: context.tr('practiceThisCourse'),
            subtitle: context.tr('practiceThisCourseSubtitle'),
            onTap: () => context.push('/games', extra: course.id),
          ),
          if (progress.percentage >= 100) ...[
            const SizedBox(height: 16),
            _buildCourseCompleteBanner(course.id),
          ],
          const SizedBox(height: 24),
          Text(
            context.trPlural('lessonsHeader', lessons.length),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ..._buildLessonStepper(lessons),
        ],
      ),
    );
  }

  Widget _buildCourseCompleteBanner(int courseId) {
    final tr = context.tr;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tr('courseCompleteBanner'),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadingCertificate
                ? null
                : () => _openCertificate(courseId),
            child: _loadingCertificate
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(tr('view')),
          ),
        ],
      ),
    );
  }

  Future<void> _openCertificate(int courseId) async {
    setState(() => _loadingCertificate = true);
    try {
      final certificates = await context.read<ApiServices>().certificates.me();
      Certificate? certificate;
      for (final c in certificates) {
        if (c.courseId == courseId) {
          certificate = c;
          break;
        }
      }
      if (!mounted) return;
      if (certificate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.trRead('certificateStillIssuing'))),
        );
        return;
      }
      context.push(
        '/profile/certificates/${certificate.id}',
        extra: certificate,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(extractErrorMessage(context, e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingCertificate = false);
    }
  }

  /// Builds the lesson list as a connected stepper: completed lessons
  /// collapse into one summary node (tap to expand), the next unlocked
  /// lesson gets a highlighted "current" card, and everything after it is
  /// shown locked. Matches the sequential-unlock model in `_lessons`.
  List<Widget> _buildLessonStepper(List<Lesson> lessons) {
    final tr = context.tr;
    final completed = <Lesson>[];
    Lesson? current;
    final locked = <Lesson>[];
    for (final lesson in lessons) {
      if (lesson.completed) {
        completed.add(lesson);
      } else if (current == null) {
        current = lesson;
      } else {
        locked.add(lesson);
      }
    }

    final nodes = <Widget>[];

    if (completed.isNotEmpty) {
      final isLastOverall = current == null && locked.isEmpty;
      nodes.add(
        _stepperRow(
          circle: _stepCircle(
            background: AppColors.success,
            icon: Icons.check,
            iconColor: Colors.white,
          ),
          lineColor: AppColors.success,
          isLast: isLastOverall && !_showCompletedLessons,
          child: InkWell(
            onTap: () =>
                setState(() => _showCompletedLessons = !_showCompletedLessons),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        completed.length == 1
                            ? tr('lessonSingularCompleted')
                            : tr('lessonsRangeCompleted', {
                                'n': completed.length,
                              }),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _showCompletedLessons
                            ? tr('tapToCollapse')
                            : tr('allPassedTapToReview'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _showCompletedLessons ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      );

      if (_showCompletedLessons) {
        for (var i = 0; i < completed.length; i++) {
          final isLastOfCompleted = i == completed.length - 1;
          nodes.add(
            _stepperRow(
              circle: _stepCircle(
                background: AppColors.success,
                icon: Icons.check,
                iconColor: Colors.white,
                small: true,
              ),
              lineColor: AppColors.success,
              isLast: isLastOfCompleted && current == null && locked.isEmpty,
              child: _lessonRow(
                completed[i],
                subtitle: tr('lessonCompleted'),
                onTap: () => context.push('/lessons/${completed[i].id}'),
              ),
            ),
          );
        }
      }
    }

    if (current != null) {
      nodes.add(
        _stepperRow(
          circle: _stepCircle(
            background: AppColors.primary,
            icon: Icons.play_arrow_rounded,
            iconColor: Colors.white,
            ring: true,
          ),
          lineColor: AppColors.primary,
          isLast: locked.isEmpty,
          child: _currentLessonCard(current),
        ),
      );
    }

    for (var i = 0; i < locked.length; i++) {
      nodes.add(
        _stepperRow(
          circle: _stepCircle(
            background: AppColors.surfaceHigh,
            icon: Icons.lock_outline,
            iconColor: AppColors.textMuted,
            outlined: true,
          ),
          lineColor: AppColors.border,
          isLast: i == locked.length - 1,
          child: _lessonRow(
            locked[i],
            subtitle: tr('locked'),
            muted: true,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr('completeThePreviousLessonFirst'))),
              );
            },
          ),
        ),
      );
    }

    return nodes;
  }

  Widget _stepperRow({
    required Widget circle,
    required Color lineColor,
    required bool isLast,
    required Widget child,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                circle,
                if (!isLast)
                  Expanded(child: Container(width: 2, color: lineColor)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepCircle({
    required Color background,
    required IconData icon,
    required Color iconColor,
    bool small = false,
    bool outlined = false,
    bool ring = false,
  }) {
    final size = small ? 34.0 : 42.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: outlined ? Border.all(color: AppColors.border) : null,
        boxShadow: ring
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  blurRadius: 0,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: Icon(icon, size: small ? 16 : 20, color: iconColor),
    );
  }

  Widget _lessonRow(
    Lesson lesson, {
    required String subtitle,
    bool muted = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: muted ? AppColors.textMuted : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: muted
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            muted ? Icons.lock_outline : Icons.chevron_right,
            size: 18,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _currentLessonCard(Lesson lesson) {
    final tr = context.tr;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/lessons/${lesson.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tr('lessonNumberBadge', {'n': lesson.orderIndex + 1}),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: AppColors.primaryHigh,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lesson.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              lesson.hasQuiz
                  ? tr('includesAQuiz')
                  : tr('lessonN', {'n': lesson.orderIndex + 1}),
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton.icon(
                onPressed: () => context.push('/lessons/${lesson.id}'),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: Text(tr('continueButton')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(CourseProgress progress) {
    final tr = context.tr;
    final percentage = (progress.percentage / 100).clamp(0, 1).toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr('yourProgress'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${progress.percentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryHigh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 10,
              backgroundColor: AppColors.surfaceHigh,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('lessonsCompleteCount', {
              'completed': progress.completedLessons,
              'total': progress.totalLessons,
            }),
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(
    String label, {
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: foreground,
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    final tr = context.tr;
    final course = _course!;
    final reviews = _reviews!;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (course.averageRating != null) ...[
            _buildRatingSummary(course),
            const SizedBox(height: 16),
          ],
          FilledButton.icon(
            onPressed: _openReviewDialog,
            icon: const Icon(Icons.star_outline),
            label: Text(tr('writeAReview')),
          ),
          const SizedBox(height: 20),
          if (reviews.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.rate_review_outlined,
                    size: 32,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tr('noReviewsYet'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            ...reviews.map((review) => _buildReviewCard(review)),
        ],
      ),
    );
  }

  Widget _buildRatingSummary(Course course) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Text(
            course.averageRating!.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < course.averageRating!.round()
                        ? Icons.star
                        : Icons.star_border,
                    size: 18,
                    color: Colors.amber,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                context.trPlural('reviewCount', course.reviewCount),
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    final initial = review.reviewerName.isNotEmpty
        ? review.reviewerName[0].toUpperCase()
        : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.reviewerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                DateFormat.yMMMd().format(review.createdAt.toLocal()),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < review.rating ? Icons.star : Icons.star_border,
                size: 15,
                color: Colors.amber,
              ),
            ),
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
