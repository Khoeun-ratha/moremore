import 'package:dio/dio.dart';

import '../config.dart';
import '../state/auth_store.dart';

/// Builds the shared [Dio] instance used by all resource API classes.
///
/// Mirrors admin/src/api/http.ts: attaches the bearer token to every request,
/// and on a 401 (that isn't itself a refresh/login call) shares a single
/// in-flight refresh so N parallel 401s trigger exactly one `/auth/refresh`.
/// If refresh fails, it logs the user out — the router's redirect (listening
/// to AuthStore) then bounces them to /login.
Dio buildApiClient(AuthStore authStore) {
  final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (authStore.accessToken != null) {
          options.headers['Authorization'] = 'Bearer ${authStore.accessToken}';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final response = error.response;
        final requestOptions = error.requestOptions;

        if (response?.statusCode != 401 ||
            requestOptions.extra['retried'] == true) {
          return handler.next(error);
        }
        if (requestOptions.path.contains('/auth/refresh') ||
            requestOptions.path.contains('/auth/login')) {
          await authStore.logout();
          return handler.next(error);
        }

        try {
          authStore.refreshInFlight ??= authStore.refresh().whenComplete(() {
            authStore.refreshInFlight = null;
          });
          final newToken = await authStore.refreshInFlight!;

          requestOptions.extra['retried'] = true;
          requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await dio.fetch(requestOptions);
          return handler.resolve(retryResponse);
        } catch (_) {
          await authStore.logout();
          return handler.next(error);
        }
      },
    ),
  );

  return dio;
}
