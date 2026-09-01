import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../api/api_error.dart';
import '../../api/api_services.dart';
import '../../models/certificate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_view.dart';

class MyCertificatesScreen extends StatefulWidget {
  const MyCertificatesScreen({super.key});

  @override
  State<MyCertificatesScreen> createState() => _MyCertificatesScreenState();
}

class _MyCertificatesScreenState extends State<MyCertificatesScreen> {
  List<Certificate>? _certificates;
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
      final certificates = await context.read<ApiServices>().certificates.me();
      setState(() => _certificates = certificates);
    } catch (e) {
      setState(() => _error = extractErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Certificates')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    final certificates = _certificates!;
    if (certificates.isEmpty) {
      return const Center(
        child: Text('Complete a course to earn your first certificate.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: certificates.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final certificate = certificates[index];
          return Card(
            child: ListTile(
              leading: const Icon(
                Icons.workspace_premium_outlined,
                color: AppColors.warning,
              ),
              title: Text(certificate.courseTitle),
              subtitle: Text(
                'Issued ${DateFormat.yMMMd().format(certificate.issuedAt.toLocal())}',
              ),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => context.push(
                '/profile/certificates/${certificate.id}',
                extra: certificate,
              ),
            ),
          );
        },
      ),
    );
  }
}
