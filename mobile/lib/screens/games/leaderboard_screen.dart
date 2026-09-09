import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_error.dart';
import '../../api/api_services.dart';
import '../../l10n/l10n_extension.dart';
import '../../models/game.dart';
import '../../state/auth_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_view.dart';

/// Every player's single best Quick Challenge round, ranked by score.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<LeaderboardEntry>? _entries;
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
      final entries = await context.read<ApiServices>().games.leaderboard();
      if (mounted) setState(() => _entries = entries);
    } catch (e) {
      if (mounted) setState(() => _error = extractErrorMessage(context, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('leaderboardTitle'))),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    final tr = context.tr;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    final entries = _entries!;
    if (entries.isEmpty) {
      return Center(child: Text(tr('noLeaderboardEntries')));
    }

    final myUserId = context.watch<AuthStore>().user?.id;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final entry = entries[index];
          final isMe = entry.userId == myUserId;
          final medalColor = switch (entry.rank) {
            1 => const Color(0xFFD4AF37),
            2 => const Color(0xFFA8A8A8),
            3 => const Color(0xFFB08D57),
            _ => null,
          };

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  width: 32,
                  child: medalColor != null
                      ? Icon(Icons.emoji_events_rounded, color: medalColor)
                      : Text(
                          '#${entry.rank}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.fullName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: isMe ? FontWeight.w700 : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${entry.percentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryHigh,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
