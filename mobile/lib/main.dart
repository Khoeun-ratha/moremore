import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'api/api_client.dart';
import 'api/api_services.dart';
import 'router/app_router.dart';
import 'screens/splash/splash_screen.dart';
import 'state/auth_store.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const LearningPlatformApp());
}

class LearningPlatformApp extends StatelessWidget {
  const LearningPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthStore()..restoreSession(),
      child: Builder(
        builder: (context) {
          final authStore = context.read<AuthStore>();
          return Provider<ApiServices>(
            create: (_) => ApiServices(buildApiClient(authStore)),
            child: const _AppRoot(),
          );
        },
      ),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  late final GoRouter _router = buildAppRouter(context.read<AuthStore>());

  @override
  Widget build(BuildContext context) {
    final authStore = context.watch<AuthStore>();
    if (authStore.isRestoring) {
      return MaterialApp(theme: AppTheme.light, home: const SplashScreen());
    }

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Learning Platform',
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
