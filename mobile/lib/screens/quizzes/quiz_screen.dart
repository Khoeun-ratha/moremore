import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../api/api_error.dart';
import '../../api/api_services.dart';
import '../../models/lesson.dart';
import '../../models/quiz.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_view.dart';
import '../../widgets/quiz_choice_tile.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.lessonId});

  final int lessonId;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  Quiz? _quiz;
  Lesson? _lesson;
  final Map<int, int> _answers = {}; // question_id -> choice_id
  int _currentIndex = 0;
  bool _loading = true;
  bool _submitting = false;
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
        api.lessons.getQuiz(widget.lessonId),
        api.lessons.get(widget.lessonId),
      ]);
      setState(() {
        _quiz = results[0] as Quiz;
        _lesson = results[1] as Lesson;
        _currentIndex = 0;
      });
    } catch (e) {
      setState(() => _error = extractErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final quiz = _quiz!;
    setState(() => _submitting = true);
    try {
      final result = await context.read<ApiServices>().quizzes.submit(
        quiz.id,
        _answers,
      );
      if (mounted) {
        // Await the push so that whenever the result screen is popped (e.g. via
        // "Retake Quiz"), this screen resets rather than showing stale answers.
        await context.push(
          '/quiz-result',
          extra: QuizResultArgs(result: result, courseId: _lesson!.courseId),
        );
        if (mounted) {
          setState(() {
            _answers.clear();
            _currentIndex = 0;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(extractErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _goPrevious() {
    if (_currentIndex == 0) return;
    setState(() => _currentIndex -= 1);
  }

  void _goNext() {
    final quiz = _quiz!;
    final isLast = _currentIndex == quiz.questions.length - 1;
    if (isLast) {
      _submit();
    } else {
      setState(() => _currentIndex += 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_quiz?.title ?? 'Quiz'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    final quiz = _quiz!;
    if (quiz.questions.isEmpty) {
      return const Center(child: Text('This quiz has no questions yet.'));
    }

    final question = quiz.questions[_currentIndex];
    final total = quiz.questions.length;
    final answered = _answers[question.id] != null;
    final isLast = _currentIndex == total - 1;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Quiz Progress',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Question ${_currentIndex + 1} of $total',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(total, (i) {
                    final Color color;
                    if (i < _currentIndex) {
                      color = AppColors.primary;
                    } else if (i == _currentIndex) {
                      color = AppColors.primaryHigh;
                    } else {
                      color = AppColors.border;
                    }
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i == total - 1 ? 0 : 4),
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              key: ValueKey(question.id),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'MULTIPLE CHOICE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.primaryHigh,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  question.text,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select the answer you believe is correct.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                ...question.choices.map(
                  (choice) => QuizChoiceTile(
                    text: choice.text,
                    selected: _answers[question.id] == choice.id,
                    onTap: () =>
                        setState(() => _answers[question.id] = choice.id),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _currentIndex == 0 ? null : _goPrevious,
                    child: const Text('Previous'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: !answered || _submitting ? null : _goNext,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(isLast ? 'Submit answers' : 'Next Question'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
