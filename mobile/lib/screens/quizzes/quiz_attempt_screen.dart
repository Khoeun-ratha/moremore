import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../api/api_error.dart';
import '../../api/api_services.dart';
import '../../models/quiz.dart';
import '../../widgets/error_view.dart';
import 'quiz_result_screen.dart';

/// Loads a single past [QuizResult] by attempt id and displays it read-only,
/// so a learner can revisit how they did on a quiz after the fact.
class QuizAttemptScreen extends StatefulWidget {
  const QuizAttemptScreen({super.key, required this.attemptId});

  final int attemptId;

  @override
  State<QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends State<QuizAttemptScreen> {
  QuizResult? _result;
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
      final result = await context.read<ApiServices>().quizzes.getAttemptDetail(
        widget.attemptId,
      );
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = extractErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Attempt Details'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Attempt Details'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ),
        body: ErrorView(message: _error!, onRetry: _load),
      );
    }
    return QuizResultScreen(result: _result!, isHistorical: true);
  }
}
