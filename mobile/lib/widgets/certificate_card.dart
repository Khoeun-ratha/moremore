import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n_extension.dart';
import '../models/certificate.dart';
import '../theme/app_theme.dart';

/// The certificate document content — reused by the certificate detail
/// screen and the course-complete celebration screen, each of which wraps
/// it in their own card styling.
class CertificateCard extends StatelessWidget {
  const CertificateCard({
    super.key,
    required this.certificate,
    required this.learnerName,
  });

  final Certificate certificate;
  final String learnerName;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.workspace_premium, size: 56, color: AppColors.warning),
        const SizedBox(height: 16),
        Text(
          tr('certificateOfCompletion'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: AppColors.primaryHigh,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          tr('thisCertifiesThat'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(
          learnerName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          tr('hasSuccessfullyCompleted'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(
          certificate.courseTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryHigh,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          DateFormat.yMMMMd().format(certificate.issuedAt.toLocal()),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Text(
          certificate.certificateNumber,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
