import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../api/api_services.dart';
import '../../l10n/l10n_extension.dart';
import '../../state/auth_store.dart';
import '../../state/locale_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/media.dart';
import '../../widgets/stat_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _enrolledCourseCount;
  int? _certificateCount;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final api = context.read<ApiServices>();
      final progress = await api.progress.me();
      final certificates = await api.certificates.me();
      if (!mounted) return;
      setState(() {
        _enrolledCourseCount = progress.courses
            .where((c) => c.percentage > 0)
            .length;
        _certificateCount = certificates.length;
      });
    } catch (_) {
      // Best-effort: stats aren't essential to using the profile screen.
    }
  }

  Future<void> _confirmLogout(AuthStore auth) async {
    final tr = context.tr;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('logOut')),
        content: Text(tr('logOutConfirmMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(tr('logOut')),
          ),
        ],
      ),
    );
    if (confirmed == true) auth.logout();
  }

  Future<void> _pickLanguage() async {
    final localeStore = context.read<LocaleStore>();
    final tr = context.tr;
    final current = context.read<LocaleStore>().locale?.languageCode ?? 'en';
    final chosen = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(tr('language')),
        children: [
          RadioListTile<String>(
            value: 'en',
            groupValue: current,
            title: Text(tr('languageEnglish')),
            onChanged: (v) => Navigator.pop(dialogContext, v),
          ),
          RadioListTile<String>(
            value: 'km',
            groupValue: current,
            title: Text(tr('languageKhmer')),
            onChanged: (v) => Navigator.pop(dialogContext, v),
          ),
        ],
      ),
    );
    if (chosen != null && chosen != current) {
      await localeStore.setLocale(Locale(chosen));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final auth = context.watch<AuthStore>();
    final user = auth.user;
    final initial = (user?.fullName.isNotEmpty ?? false)
        ? user!.fullName[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(tr('profileTitle'))),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadStats,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    image:
                        (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(mediaUrl(user.avatarUrl)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                      ? Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user?.fullName ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Center(
                child: Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      icon: Icons.menu_book_outlined,
                      iconColor: AppColors.primary,
                      value: _enrolledCourseCount?.toString() ?? '—',
                      label: tr('coursesLabel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      icon: Icons.workspace_premium_outlined,
                      iconColor: AppColors.warning,
                      value: _certificateCount?.toString() ?? '—',
                      label: tr('certificatesLabel'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _MenuGroup(
                children: [
                  _MenuTile(
                    icon: Icons.workspace_premium_outlined,
                    iconColor: AppColors.warning,
                    label: tr('myCertificatesMenu'),
                    onTap: () => context.push('/profile/certificates'),
                  ),
                  _MenuTile(
                    icon: Icons.edit_outlined,
                    iconColor: AppColors.primary,
                    label: tr('editProfileMenu'),
                    onTap: () => context.push('/profile/edit'),
                  ),
                  _MenuTile(
                    icon: Icons.lock_outline,
                    iconColor: AppColors.primaryHigh,
                    label: tr('changePasswordMenu'),
                    onTap: () => context.push('/profile/change-password'),
                  ),
                  _MenuTile(
                    icon: Icons.language_outlined,
                    iconColor: AppColors.success,
                    label: tr('language'),
                    onTap: _pickLanguage,
                  ),
                  _MenuTile(
                    icon: Icons.forum_outlined,
                    iconColor: AppColors.success,
                    label: tr('feedbackSuggestionsMenu'),
                    onTap: () => context.push('/profile/feedback'),
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _MenuGroup(
                children: [
                  _MenuTile(
                    icon: Icons.logout,
                    iconColor: AppColors.danger,
                    label: tr('logOut'),
                    labelColor: AppColors.danger,
                    onTap: () => _confirmLogout(auth),
                    showChevron: false,
                    showDivider: false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
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
      child: Column(children: children),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.showChevron = true,
    this.showDivider = true,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final bool showChevron;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: labelColor ?? AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (showChevron)
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
