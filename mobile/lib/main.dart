import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'api/api_client.dart';
import 'api/api_services.dart';
import 'l10n/translations.dart';
import 'router/app_router.dart';
import 'screens/splash/splash_screen.dart';
import 'state/auth_store.dart';
import 'state/locale_store.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const LearningPlatformApp());
}

class LearningPlatformApp extends StatelessWidget {
  const LearningPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthStore()..restoreSession()),
        ChangeNotifierProvider(create: (_) => LocaleStore()),
        ChangeNotifierProvider(create: (_) => Translations()),
      ],
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
  String? _loadedForLanguageCode;

  @override
  Widget build(BuildContext context) {
    final authStore = context.watch<AuthStore>();
    final localeStore = context.watch<LocaleStore>();
    final translations = context.watch<Translations>();

    final wantedLanguageCode = localeStore.locale?.languageCode;
    if (!translations.isLoaded ||
        _loadedForLanguageCode != wantedLanguageCode) {
      _loadedForLanguageCode = wantedLanguageCode;
      translations.load(wantedLanguageCode);
    }

    if (authStore.isRestoring || !translations.isLoaded) {
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
