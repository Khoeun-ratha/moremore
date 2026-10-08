// Session-restore behaviour of AuthStore against a scripted fake backend.
// Regression cover for users being logged out every time they reopened the
// app more than 45 minutes (the access-token lifetime) after last using it.
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/state/auth_store.dart';

const _user = {
  'id': 1,
  'email': 'learner@example.com',
  'phone': null,
  'full_name': 'Learner',
  'gender': null,
  'avatar_url': null,
  'role': 'user',
  'is_active': true,
  'created_at': '2026-01-01T00:00:00',
};

/// Answers each request with whatever [handler] returns for its path.
class _FakeBackend implements HttpClientAdapter {
  _FakeBackend(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  final calls = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add('${options.method} ${options.path}');
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

AuthStore _storeWith(_FakeBackend backend) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1'))
    ..httpClientAdapter = backend;
  return AuthStore(bareClient: dio);
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'expired-access',
      'refresh_token': 'valid-refresh',
    });
  });

  test('an expired access token is refreshed instead of logging out', () async {
    final backend = _FakeBackend((options) {
      final auth = options.headers['Authorization'];
      if (options.path == '/auth/me') {
        return auth == 'Bearer new-access'
            ? _json(_user)
            : _json({'error': 'Token expired'}, 401);
      }
      if (options.path == '/auth/refresh') {
        return _json({
          'access_token': 'new-access',
          'refresh_token': 'new-refresh',
          'token_type': 'bearer',
        });
      }
      return _json({}, 404);
    });
    final store = _storeWith(backend);

    await store.restoreSession();

    expect(store.isAuthenticated, isTrue);
    expect(store.accessToken, 'new-access');
    expect(store.refreshToken, 'new-refresh');
    expect(backend.calls, [
      'GET /auth/me',
      'POST /auth/refresh',
      'GET /auth/me',
    ]);
  });

  test('a rejected refresh token ends the session', () async {
    final backend = _FakeBackend((options) {
      if (options.path == '/auth/logout') return _json({}, 204);
      return _json({'error': 'Invalid or expired token'}, 401);
    });
    final store = _storeWith(backend);

    await store.restoreSession();

    expect(store.isAuthenticated, isFalse);
    expect(store.refreshToken, isNull);
    expect(
      await const FlutterSecureStorage().read(key: 'refresh_token'),
      isNull,
    );
  });

  test('being offline at startup keeps the stored session', () async {
    final backend = _FakeBackend(
      (options) => throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      ),
    );
    final store = _storeWith(backend);

    await store.restoreSession();

    expect(store.isAuthenticated, isFalse);
    expect(store.isRestoring, isFalse);
    // Still on disk, so the next launch with a connection restores it.
    expect(
      await const FlutterSecureStorage().read(key: 'refresh_token'),
      'valid-refresh',
    );
  });
}
