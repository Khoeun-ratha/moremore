import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../api/api_error.dart';
import '../../api/api_services.dart';
import '../../models/course.dart';
import '../../models/lesson.dart';
import '../../models/progress.dart';
import '../../state/auth_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/media.dart';
import '../../widgets/course_card.dart';
import '../../widgets/error_view.dart';
import '../../widgets/stat_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  OverallProgress? _progress;
  List<Course>? _recommended;
  Lesson? _nextLesson;
  bool _loading = true;
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
      final results = await Future.wait([
        api.progress.me(),
        api.courses.recommended(),
      ]);
      final progress = results[0] as OverallProgress;
      Lesson? nextLesson;
      final inProgress =
          progress.courses
              .where((c) => c.percentage > 0 && c.percentage < 100)
              .toList()
            ..sort((a, b) => b.percentage.compareTo(a.percentage));
      if (inProgress.isNotEmpty) {
        try {
          final lessons = await api.lessons.listForCourse(
            inProgress.first.courseId,
          );
          nextLesson = lessons.firstWhere(
            (l) => !l.completed,
            orElse: () => lessons.last,
          );
        } catch (_) {
          // Best-effort: falls back to opening the course page instead of the exact lesson.
        }
      }
      setState(() {
        _progress = progress;
        _recommended = results[1] as List<Course>;
        _nextLesson = nextLesson;
      });
    } catch (e) {
      setState(() => _error = extractErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthStore>().user;
    final name = user?.fullName.trim() ?? '';
    final firstName = name.isEmpty ? '' : name.split(' ').first;
    final initial = firstName.isEmpty ? 'U' : firstName[0].toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _HomeHeaderDelegate(
                  greeting: _greeting(),
                  name: name.isEmpty ? 'Welcome back' : name,
                  initial: initial,
                  avatarUrl: user?.avatarUrl,
                  onAvatarTap: () => context.go('/profile'),
                ),
              ),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorView(message: _error!, onRetry: _load),
      );
    }

    final progress = _progress!;
    final recommended = _recommended!;
    final enrolled = progress.courses.where((c) => c.percentage > 0).toList();
    final completedCount = enrolled.where((c) => c.percentage >= 100).length;
    final inProgress = enrolled.where((c) => c.percentage < 100).toList()
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
    final continueCourse = inProgress.isEmpty ? null : inProgress.first;

    if (enrolled.isEmpty && recommended.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            _buildStatsRow(
              enrolled.length,
              completedCount,
              progress.overallPercentage,
            ),
            const SizedBox(height: 20),
            _buildEmptyState(),
          ]),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildStatsRow(
            enrolled.length,
            completedCount,
            progress.overallPercentage,
          ),
          const SizedBox(height: 20),
          if (continueCourse != null) ...[
            _buildContinueLearningCard(continueCourse, _nextLesson),
            const SizedBox(height: 28),
          ],
          if (enrolled.isNotEmpty) ...[
            _sectionHeader(
              'Enrolled Courses',
              onSeeAll: () => context.go('/progress'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 126,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: enrolled.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    _buildEnrolledCard(enrolled[index]),
              ),
            ),
            const SizedBox(height: 28),
          ],
          if (recommended.isNotEmpty) ...[
            _sectionHeader(
              'Recommended for You',
              onSeeAll: () => context.go('/courses'),
            ),
            const SizedBox(height: 12),
            ...recommended.map(
              (course) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CourseCard(
                  course: course,
                  onTap: () => context.push('/courses/${course.id}'),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.surfaceHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.explore_outlined,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Start learning something new',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Browse our course catalog to find something you\'ll love.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.go('/courses'),
              child: const Text('Browse Courses'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    int enrolledCount,
    int completedCount,
    double overallPercentage,
  ) {
    return Row(
      children: [
        Expanded(
          child: StatTile(
            icon: Icons.menu_book_outlined,
            iconColor: AppColors.primary,
            value: '$enrolledCount',
            label: 'Enrolled',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatTile(
            icon: Icons.check_circle_outline,
            iconColor: AppColors.success,
            value: '$completedCount',
            label: 'Completed',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatTile(
            icon: Icons.trending_up,
            iconColor: AppColors.warning,
            value: '${overallPercentage.toStringAsFixed(0)}%',
            label: 'Overall',
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onSeeAll}) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      if (onSeeAll != null)
        GestureDetector(
          onTap: onSeeAll,
          child: const Text(
            'See all',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryHigh,
            ),
          ),
        ),
    ],
  );

  Widget _buildContinueLearningCard(CourseProgress course, Lesson? nextLesson) {
    final next = nextLesson;
    final showNextLesson = next != null && next.courseId == course.courseId;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryHigh],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'CONTINUE LEARNING',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            course.courseTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          if (showNextLesson) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_arrow_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Next: ${next.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (course.percentage / 100).clamp(0, 1),
              minHeight: 8,
              backgroundColor: Colors.white24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${course.completedLessons}/${course.totalLessons} lessons · ${course.percentage.toStringAsFixed(0)}% complete',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryHigh,
              ),
              onPressed: () => showNextLesson
                  ? context.push('/lessons/${next.id}')
                  : context.push('/courses/${course.courseId}'),
              child: Text(
                showNextLesson
                    ? 'Resume Lesson ${next.orderIndex + 1}'
                    : 'Resume',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrolledCard(CourseProgress course) {
    final percentage = (course.percentage / 100).clamp(0, 1).toDouble();
    final completed = course.percentage >= 100;
    return SizedBox(
      width: 172,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/courses/${course.courseId}'),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 38,
                          height: 38,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: percentage,
                                strokeWidth: 3.5,
                                backgroundColor: AppColors.surfaceHigh,
                                color: course.percentage >= 100
                                    ? AppColors.success
                                    : AppColors.primary,
                              ),
                              Text(
                                course.percentage.toStringAsFixed(0),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${course.completedLessons}/${course.totalLessons}\nlessons',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      course.courseTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (completed)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  _HomeHeaderDelegate({
    required this.greeting,
    required this.name,
    required this.initial,
    required this.avatarUrl,
    required this.onAvatarTap,
  });

  final String greeting;
  final String name;
  final String initial;
  final String? avatarUrl;
  final VoidCallback onAvatarTap;

  static const double _height = 104;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: _height,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: overlapsContent
            ? const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onAvatarTap,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  image: (avatarUrl != null && avatarUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(mediaUrl(avatarUrl)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: (avatarUrl == null || avatarUrl!.isEmpty)
                    ? Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) {
    return oldDelegate.greeting != greeting ||
        oldDelegate.name != name ||
        oldDelegate.initial != initial ||
        oldDelegate.avatarUrl != avatarUrl;
  }
}
