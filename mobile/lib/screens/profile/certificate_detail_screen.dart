import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/certificate.dart';
import '../../state/auth_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/certificate_card.dart';

class CertificateDetailScreen extends StatelessWidget {
  const CertificateDetailScreen({super.key, required this.certificate});

  final Certificate certificate;

  @override
  Widget build(BuildContext context) {
    final learnerName = context.watch<AuthStore>().user?.fullName ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Certificate')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CertificateCard(
                      certificate: certificate,
                      learnerName: learnerName,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
