import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../api/api_error.dart';
import '../../api/api_services.dart';
import '../../l10n/l10n_extension.dart';
import '../../models/game.dart';
import '../../state/auth_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_view.dart';
import '../../widgets/game_entry_card.dart';
import '../../widgets/stat_tile.dart';

/// Landing screen for the bottom nav's Game tab — Quick Challenge plus a
/// personal best-score summary and a live leaderboard preview, so players
/// see where they stand without leaving the hub.
class GameHomeScreen extends StatefulWidget {
  const GameHomeScreen({super.key});

  @override
  State<GameHomeScreen> createState() => _GameHomeScreenState();
}

class _GameHomeScreenState extends State<GameHomeScreen> {
  List<GameAttempt>? _attempts;
  List<LeaderboardEntry>? _leaderboard;
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
      final api = context.read<ApiServices>().games;
      final results = await Future.wait([api.myAttempts(), api.leaderboard()]);
      if (mounted) {
        setState(() {
          _attempts = results[0] as List<GameAttempt>;
          _leaderboard = results[1] as List<LeaderboardEntry>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = extractErrorMessage(context, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('gameHubTitle'))),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    final tr = context.tr;
    final attempts = _attempts!;
    final leaderboard = _leaderboard!;
    final myUserId = context.watch<AuthStore>().user?.id;

    double? bestPercentage;
    for (final a in attempts) {
      if (a.total == 0) continue;
      final pct = a.score / a.total * 100;
      if (bestPercentage == null || pct > bestPercentage) bestPercentage = pct;
    }
    final runsPlayed = attempts.length;
    LeaderboardEntry? myRankEntry;
    for (final entry in leaderboard) {
      if (entry.userId == myUserId) {
        myRankEntry = entry;
        break;
      }
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.emoji_events_outlined,
                  iconColor: AppColors.warning,
                  value: bestPercentage == null
                      ? '—'
                      : '${bestPercentage.toStringAsFixed(0)}%',
                  label: tr('bestScoreLabel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  icon: Icons.leaderboard_outlined,
                  iconColor: AppColors.primary,
                  value: myRankEntry == null ? '—' : '#${myRankEntry.rank}',
                  label: tr('yourRankLabel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  icon: Icons.history_rounded,
                  iconColor: AppColors.success,
                  value: '$runsPlayed',
                  label: tr('runsPlayedLabel'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            tr('playSectionHeader'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GameEntryCard(
            title: tr('quickChallenge'),
            subtitle: tr('quickChallengeSubtitle'),
            onTap: () => context.push('/games/quick'),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr('leaderboardTitle'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/leaderboard'),
                child: Text(tr('seeAll')),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (leaderboard.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  tr('noLeaderboardEntries'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...leaderboard
                .take(5)
                .map(
                  (entry) => _LeaderboardPreviewRow(
                    entry: entry,
                    isMe: entry.userId == myUserId,
                  ),
                ),
        ],
      ),
    );
  }
}

class _LeaderboardPreviewRow extends StatelessWidget {
  const _LeaderboardPreviewRow({required this.entry, required this.isMe});

  final LeaderboardEntry entry;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final medalColor = switch (entry.rank) {
      1 => const Color(0xFFD4AF37),
      2 => const Color(0xFFA8A8A8),
      3 => const Color(0xFFB08D57),
      _ => null,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMe ? AppColors.primary : AppColors.border,
            width: isMe ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: medalColor != null
                  ? Icon(
                      Icons.emoji_events_rounded,
                      size: 20,
                      color: medalColor,
                    )
                  : Text(
                      '#${entry.rank}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                entry.fullName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isMe ? FontWeight.w700 : FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '${entry.percentage.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryHigh,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
