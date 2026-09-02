import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n_extension.dart';
import '../../models/certificate.dart';
import '../../state/auth_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/certificate_export.dart';
import '../../widgets/certificate_card.dart';

/// Shown right after a learner finishes a course's last lesson — the
/// in-flow celebration moment that a freshly-issued certificate otherwise
/// never gets (previously it only surfaced later, buried in Profile ->
/// My Certificates).
class CertificateCelebrationScreen extends StatefulWidget {
  const CertificateCelebrationScreen({super.key, required this.certificate});

  final Certificate certificate;

  @override
  State<CertificateCelebrationScreen> createState() =>
      _CertificateCelebrationScreenState();
}

class _CertificateCelebrationScreenState
    extends State<CertificateCelebrationScreen> {
  final _boundaryKey = GlobalKey();
  bool _saving = false;

  static const _confettiDots = [
    Offset(28, 28),
    Offset(300, 60),
    Offset(200, 14),
    Offset(44, 100),
    Offset(330, 86),
    Offset(16, 138),
    Offset(250, 138),
    Offset(130, 50),
    Offset(340, 178),
  ];

  Future<void> _download() async {
    setState(() => _saving = true);
    await saveWidgetToGallery(
      boundaryKey: _boundaryKey,
      context: context,
      fileName: 'certificate_${widget.certificate.certificateNumber}',
    );
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final certificate = widget.certificate;
    final learnerName = context.watch<AuthStore>().user?.fullName ?? '';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryHigh],
          ),
        ),
        child: Stack(
          children: [
            for (final dot in _confettiDots)
              Positioned(
                left: dot.dx,
                top: dot.dy,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => context.go('/home'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      tr('courseCompleteExclaim'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr('finishedCourseNiceWork', {
                        'course': certificate.courseTitle,
                      }),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    RepaintBoundary(
                      key: _boundaryKey,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.28),
                              blurRadius: 32,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: CertificateCard(
                          certificate: certificate,
                          learnerName: learnerName.isEmpty
                              ? tr('learnerNameFallback')
                              : learnerName,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryHigh,
                        ),
                        onPressed: _saving ? null : _download,
                        icon: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryHigh,
                                ),
                              )
                            : const Icon(Icons.download_outlined),
                        label: Text(
                          _saving
                              ? tr('savingEllipsis')
                              : tr('downloadCertificate'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                        onPressed: () => context.go('/courses'),
                        child: Text(tr('continueLearningButton')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
