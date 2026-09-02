import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../api/api_error.dart';
import '../../api/api_services.dart';
import '../../l10n/l10n_extension.dart';
import '../../models/game.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_view.dart';
import '../../widgets/quiz_choice_tile.dart';
import 'game_result_screen.dart';

/// A quick, replayable practice round: a random sample of quiz questions
/// pulled from every course (or one course, when [courseId] is given), with
/// nothing tied to lesson completion — purely for practice/fun.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.courseId});

  final int? courseId;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<GameQuestion>? _questions;
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
      _answers.clear();
      _currentIndex = 0;
    });
    try {
      final questions = await context.read<ApiServices>().games.randomQuiz(
        courseId: widget.courseId,
      );
      if (mounted) setState(() => _questions = questions);
    } catch (e) {
      if (mounted) setState(() => _error = extractErrorMessage(context, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final result = await context.read<ApiServices>().games.submit(
        _answers,
        courseId: widget.courseId,
      );
      if (mounted) {
        context.pushReplacement(
          '/game-result',
          extra: GameResultArgs(result: result, courseId: widget.courseId),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(extractErrorMessage(context, e))),
        );
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
    final isLast = _currentIndex == _questions!.length - 1;
    if (isLast) {
      _submit();
    } else {
      setState(() => _currentIndex += 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('gameTitle')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: AnimatedSwitcher(
        duration: AppMotion.fast,
        switchInCurve: AppMotion.curve,
        switchOutCurve: AppMotion.curve,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final tr = context.tr;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    final questions = _questions!;
    if (questions.isEmpty) {
      return Center(child: Text(tr('noQuestionsYet')));
    }

    final question = questions[_currentIndex];
    final total = questions.length;
    final selectedChoiceId = _answers[question.id];
    final answered = selectedChoiceId != null;
    final answeredCorrectly =
        answered &&
        question.choices.any((c) => c.isCorrect && c.id == selectedChoiceId);
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
                    Text(
                      tr('gameTitle'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      tr('questionOfTotal', {
                        'n': _currentIndex + 1,
                        'total': total,
                      }),
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
                      color = AppColors.warning;
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
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tr('multipleChoice'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.warning,
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
                Text(
                  tr('selectAnswerHint'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                ...question.choices.map((choice) {
                  final feedback = !answered
                      ? ChoiceFeedback.none
                      : choice.isCorrect
                      ? ChoiceFeedback.correct
                      : (choice.id == selectedChoiceId
                            ? ChoiceFeedback.incorrect
                            : ChoiceFeedback.none);
                  return QuizChoiceTile(
                    text: choice.text,
                    selected: selectedChoiceId == choice.id,
                    feedback: feedback,
                    onTap: answered
                        ? () {}
                        : () =>
                              setState(() => _answers[question.id] = choice.id),
                  );
                }),
                if (answered) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        answeredCorrectly
                            ? Icons.check_circle
                            : Icons.info_outline,
                        size: 18,
                        color: answeredCorrectly
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          answeredCorrectly
                              ? tr('correctFeedback')
                              : tr('incorrectFeedback'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: answeredCorrectly
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
                    child: Text(tr('previous')),
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
                        : Text(
                            isLast ? tr('submitAnswers') : tr('nextQuestion'),
                          ),
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
