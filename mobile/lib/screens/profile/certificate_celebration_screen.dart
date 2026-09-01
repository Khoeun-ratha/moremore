import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/certificate.dart';
import '../../state/auth_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/certificate_card.dart';

/// Shown right after a learner finishes a course's last lesson — the
/// in-flow celebration moment that a freshly-issued certificate otherwise
/// never gets (previously it only surfaced later, buried in Profile ->
/// My Certificates).
class CertificateCelebrationScreen extends StatelessWidget {
  const CertificateCelebrationScreen({super.key, required this.certificate});

  final Certificate certificate;

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

  @override
  Widget build(BuildContext context) {
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
                    const Text(
                      'Course Complete!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "You've finished ${certificate.courseTitle} — nice work.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
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
                        learnerName: learnerName.isEmpty ? 'You' : learnerName,
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryHigh,
                        ),
                        onPressed: () => context.go('/courses'),
                        child: const Text('Continue Learning'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () => context.push(
                        '/profile/certificates/${certificate.id}',
                        extra: certificate,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'View Certificate Details',
                        style: TextStyle(decoration: TextDecoration.underline),
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
