import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_error.dart';
import '../../api/api_services.dart';
import '../../l10n/l10n_extension.dart';
import '../../models/game.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_view.dart';

/// Admin-only: every Quick Challenge round played platform-wide, with the
/// current leaderboard leader pinned at the top and a delete action per
/// row for moderation. Only reachable from Profile when the signed-in
/// account has the admin or super_admin role.
class AdminGameAttemptsScreen extends StatefulWidget {
  const AdminGameAttemptsScreen({super.key});

  @override
  State<AdminGameAttemptsScreen> createState() =>
      _AdminGameAttemptsScreenState();
}

class _AdminGameAttemptsScreenState extends State<AdminGameAttemptsScreen> {
  final _searchController = TextEditingController();
  final _attempts = <AdminGameAttempt>[];
  LeaderboardEntry? _topPlayer;
  int _page = 1;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = true}) async {
    setState(() {
      if (reset) {
        _loading = true;
        _page = 1;
      } else {
        _loadingMore = true;
      }
      _error = null;
    });
    try {
      final api = context.read<ApiServices>().games;
      final page = await api.adminListAttempts(
        q: _searchController.text.trim(),
        page: _page,
      );
      final board = await api.leaderboard(limit: 1);
      setState(() {
        if (reset) {
          _attempts
            ..clear()
            ..addAll(page.items);
        } else {
          _attempts.addAll(page.items);
        }
        _hasMore = page.hasMore;
        _topPlayer = board.isEmpty ? null : board.first;
      });
    } catch (e) {
      if (mounted) setState(() => _error = extractErrorMessage(context, e));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    _page += 1;
    await _load(reset: false);
  }

  Future<void> _confirmDelete(AdminGameAttempt attempt) async {
    final tr = context.tr;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('removeAttemptTitle')),
        content: Text(
          tr('removeAttemptMessage', {'name': attempt.userFullName}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(tr('removeAttemptConfirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<ApiServices>().games.adminDeleteAttempt(attempt.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.trRead('attemptRemoved'))),
        );
        _load();
      }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('manageGamesMenu')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: tr('searchPlayers'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                isDense: true,
                filled: true,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
            ),
          ),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    final tr = context.tr;
    final topPlayer = _topPlayer;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount:
            1 + // top player card
            (_attempts.isEmpty ? 1 : _attempts.length) +
            (_hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _TopPlayerCard(entry: topPlayer);
          }
          final i = index - 1;
          if (_attempts.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text(tr('noGameAttemptsYet'))),
            );
          }
          if (i >= _attempts.length) {
            if (!_loadingMore) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
            }
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final attempt = _attempts[i];
          return _AttemptTile(
            attempt: attempt,
            onDelete: () => _confirmDelete(attempt),
          );
        },
      ),
    );
  }
}

class _TopPlayerCard extends StatelessWidget {
  const _TopPlayerCard({required this.entry});

  final LeaderboardEntry? entry;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final e = entry;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('currentTopPlayer'),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.04,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  e?.fullName ?? tr('noGameAttemptsYet'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (e != null)
            Text(
              '${e.percentage.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.warning,
              ),
            ),
        ],
      ),
    );
  }
}

class _AttemptTile extends StatelessWidget {
  const _AttemptTile({required this.attempt, required this.onDelete});

  final AdminGameAttempt attempt;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attempt.userFullName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  attempt.userEmail,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  attempt.courseTitle ?? tr('allCoursesLabel'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color:
                  (attempt.percentage >= 70
                          ? AppColors.success
                          : AppColors.textMuted)
                      .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${attempt.score}/${attempt.total} · ${attempt.percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: attempt.percentage >= 70
                    ? AppColors.success
                    : AppColors.textSecondary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.danger,
              size: 20,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
