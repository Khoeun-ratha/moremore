import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config.dart';
import '../models/user.dart';
import 'token_storage.dart';

/// Thrown by [AuthStore.register] when the account was created successfully
/// but the automatic follow-up login failed — a distinct case from
/// registration itself failing, since the account genuinely exists.
class RegisteredButLoginFailedException implements Exception {
  const RegisteredButLoginFailedException();
}

/// Holds the current session (tokens + profile) and drives auth calls.
///
/// Deliberately uses its own bare [Dio] instance (no interceptors) for
/// login/register/refresh/logout so those calls can never recurse into the
/// main API client's 401-refresh interceptor. Mirrors admin/src/stores/auth.ts.
class AuthStore extends ChangeNotifier {
  /// [bareClient] is for tests only; the app always uses the default.
  AuthStore({@visibleForTesting Dio? bareClient})
    : _bare =
          bareClient ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              // Generous enough for a free-tier host waking from sleep, but never
              // leaves the user staring at a spinner forever on a dead network.
              connectTimeout: AppConfig.connectTimeout,
              receiveTimeout: AppConfig.receiveTimeout,
            ),
          );

  final Dio _bare;
  final _tokenStorage = TokenStorage();

  String? accessToken;
  String? refreshToken;
  AppUser? user;
  bool _restoring = true;

  /// Shared in-flight refresh future — set/read by the API client's 401
  /// interceptor so concurrent 401s trigger exactly one `/auth/refresh` call.
  Future<String>? refreshInFlight;

  bool get isAuthenticated => accessToken != null && user != null;
  bool get isRestoring => _restoring;

  Future<void> _persist() async {
    if (accessToken != null && refreshToken != null) {
      await _tokenStorage.write(accessToken!, refreshToken!);
    } else {
      await _tokenStorage.clear();
    }
  }

  /// [identifier] may be either the account's email address or phone number.
  Future<void> login(String identifier, String password) async {
    final response = await _bare.post<Map<String, dynamic>>(
      '/auth/login',
      data: FormData.fromMap({'username': identifier, 'password': password}),
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final tokens = TokenPair.fromJson(response.data!);
    accessToken = tokens.accessToken;
    refreshToken = tokens.refreshToken;
    await _persist();
    await fetchCurrentUser();
  }

  Future<void> register(
    String email,
    String phone,
    String password,
    String fullName,
  ) async {
    await _bare.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'email': email,
        'phone': phone,
        'password': password,
        'full_name': fullName,
      },
    );
    try {
      await login(email, password);
    } catch (e) {
      // The account now genuinely exists server-side — a transient failure
      // here (e.g. a dropped connection right after registering) must not
      // be shown as "registration failed" or the user is stuck retrying
      // into a 409 "already registered". Signal it distinctly so the UI
      // can send them to log in instead.
      throw const RegisteredButLoginFailedException();
    }
  }

  /// Runs an authenticated call on the bare client. These calls bypass the
  /// main API client's interceptor, so they do their own one-shot refresh:
  /// on a 401 the (45-minute) access token is renewed with the refresh token
  /// and the call is retried once, instead of failing a profile edit just
  /// because the app sat open for a while.
  Future<Response<T>> _authed<T>(
    Future<Response<T>> Function(Options options) call,
  ) async {
    try {
      return await call(_bearer());
    } on DioException catch (e) {
      if (e.response?.statusCode != 401 || refreshToken == null) rethrow;
      refreshInFlight ??= refresh().whenComplete(() => refreshInFlight = null);
      await refreshInFlight;
      return call(_bearer());
    }
  }

  Options _bearer() =>
      Options(headers: {'Authorization': 'Bearer $accessToken'});

  Future<void> fetchCurrentUser() async {
    final response = await _authed(
      (options) =>
          _bare.get<Map<String, dynamic>>('/auth/me', options: options),
    );
    user = AppUser.fromJson(response.data!);
    notifyListeners();
  }

  Future<void> updateProfile({
    required String fullName,
    required String email,
    String? phone,
    Gender? gender,
  }) async {
    final response = await _authed(
      (options) => _bare.patch<Map<String, dynamic>>(
        '/auth/me',
        data: {
          'full_name': fullName,
          'email': email,
          'phone': (phone == null || phone.isEmpty) ? null : phone,
          'gender': gender == null ? null : genderToJson(gender),
        },
        options: options,
      ),
    );
    user = AppUser.fromJson(response.data!);
    notifyListeners();
  }

  Future<void> updateAvatar(String filePath) async {
    // A FormData body can only be sent once, so it is rebuilt for a retry.
    Future<FormData> buildForm() async => FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split(RegExp(r'[\\/]')).last,
      ),
    });
    final response = await _authed(
      (options) async => _bare.post<Map<String, dynamic>>(
        '/auth/me/avatar',
        data: await buildForm(),
        options: options,
      ),
    );
    user = AppUser.fromJson(response.data!);
    notifyListeners();
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await _authed(
      (options) => _bare.post<void>(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        options: options,
      ),
    );
  }

  /// Called by the API client's 401 interceptor. Returns the new access token.
  Future<String> refresh() async {
    if (refreshToken == null) throw StateError('No refresh token available');
    final response = await _bare.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    final tokens = TokenPair.fromJson(response.data!);
    accessToken = tokens.accessToken;
    refreshToken = tokens.refreshToken;
    await _persist();
    return tokens.accessToken;
  }

  /// Returns the OTP itself when the backend has no real SMS provider
  /// configured, so local/dev testing can show it in the UI directly instead
  /// of requiring access to the server log. Always null in a real deployment.
  Future<String?> forgotPassword(String phone) async {
    final response = await _bare.post<Map<String, dynamic>>(
      '/auth/forgot-password',
      data: {'phone': phone},
    );
    return response.data?['dev_code'] as String?;
  }

  Future<void> verifyResetCode(String phone, String code) async {
    await _bare.post<void>(
      '/auth/verify-reset-code',
      data: {'phone': phone, 'code': code},
    );
  }

  Future<void> resetPassword(
    String phone,
    String code,
    String newPassword,
  ) async {
    await _bare.post<void>(
      '/auth/reset-password',
      data: {'phone': phone, 'code': code, 'new_password': newPassword},
    );
  }

  Future<void> logout() async {
    final token = refreshToken;
    accessToken = null;
    refreshToken = null;
    user = null;
    await _persist();
    notifyListeners();
    if (token != null) {
      try {
        await _bare.post('/auth/logout', data: {'refresh_token': token});
      } catch (_) {
        // best-effort; token is already cleared client-side
      }
    }
  }

  /// Restores the current-user profile from a persisted token on app startup.
  Future<void> restoreSession() async {
    final stored = await _tokenStorage.read();
    if (stored != null) {
      accessToken = stored.$1;
      refreshToken = stored.$2;
      try {
        // Refreshes transparently if the stored access token has expired,
        // so reopening the app after 45+ minutes keeps the user signed in.
        await fetchCurrentUser();
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        if (status == 401 || status == 403) {
          // The session is genuinely over (refresh token expired/revoked,
          // or the account was disabled).
          await logout();
        } else {
          // Offline or server unreachable: show the login screen for now but
          // keep the stored tokens, so the next launch can still restore.
          accessToken = null;
          refreshToken = null;
        }
      } catch (_) {
        await logout();
      }
    }
    _restoring = false;
    notifyListeners();
  }
}
