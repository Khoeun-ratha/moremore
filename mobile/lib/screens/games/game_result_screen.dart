import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n_extension.dart';
import '../../models/game.dart';
import '../../theme/app_theme.dart';
import '../../widgets/score_gauge.dart';

/// Bundles a freshly-submitted [GameResult] with the scope it was played in
/// (all courses, or one), so "Play Again" can start an identical round.
class GameResultArgs {
  GameResultArgs({required this.result, required this.courseId});

  final GameResult result;
  final int? courseId;
}

class GameResultScreen extends StatelessWidget {
  const GameResultScreen({super.key, required this.result, this.courseId});

  final GameResult result;
  final int? courseId;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final didWell = result.percentage >= 70;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('gameResultsTitle')),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go('/home'),
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
                  color: (didWell ? AppColors.success : AppColors.warning)
                      .withValues(alpha: 0.06),
                ),
                child: ScoreGauge(
                  percentage: result.percentage,
                  label: tr('scoreLabel'),
                  colors: didWell
                      ? const [AppColors.success, AppColors.primary]
                      : const [AppColors.warning, AppColors.primaryHigh],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                didWell ? tr('greatJob') : tr('keepPracticing'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr('correctOfTotal', {
                  'score': result.score,
                  'total': result.total,
                }),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      context.pushReplacement('/games', extra: courseId),
                  child: Text(tr('playAgain')),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/home'),
                  child: Text(tr('backToHome')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
