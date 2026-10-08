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
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
    ),
  );

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

        final String newToken;
        try {
          authStore.refreshInFlight ??= authStore.refresh().whenComplete(() {
            authStore.refreshInFlight = null;
          });
          newToken = await authStore.refreshInFlight!;
        } on DioException catch (refreshError) {
          // Only a rejected refresh token ends the session; a dropped
          // connection mid-refresh just fails this one request.
          final status = refreshError.response?.statusCode;
          if (status == 401 || status == 403) await authStore.logout();
          return handler.next(error);
        } catch (_) {
          await authStore.logout();
          return handler.next(error);
        }

        // Kept outside the refresh try: the retried request failing (a 404,
        // a 403 on an admin-only screen, ...) is that request's own error,
        // not a reason to sign the user out.
        requestOptions.extra['retried'] = true;
        requestOptions.headers['Authorization'] = 'Bearer $newToken';
        try {
          return handler.resolve(await dio.fetch(requestOptions));
        } on DioException catch (retryError) {
          return handler.next(retryError);
        }
      },
    ),
  );

  return dio;
}
