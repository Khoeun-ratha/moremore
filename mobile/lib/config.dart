/// App-wide configuration, overridable at build/run time with --dart-define.
///
/// Defaults to the live production backend. For local development against a
/// backend running on your own machine, override it — Android emulators
/// can't reach the host machine's `localhost`; `10.0.2.2` is the emulator's
/// alias for it:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api/v1
class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://moremore-backend.onrender.com/api/v1',
  );

  /// The production backend runs on a free tier that sleeps when idle and can
  /// take close to a minute to wake, so these are deliberately generous —
  /// they exist to stop a dead network from spinning forever, not to rush
  /// a slow-but-alive server.
  static const connectTimeout = Duration(seconds: 60);
  static const receiveTimeout = Duration(seconds: 60);

  /// Root origin (no /api/v1 suffix) — used to resolve relative media URLs
  /// like `/media/videos/xyz.mp4` returned by the backend.
  static String get apiOrigin {
    final uri = Uri.parse(apiBaseUrl);
    return '${uri.scheme}://${uri.authority}';
  }

  /// Empty unless overridden via --dart-define=PRIVACY_POLICY_URL=...; when
  /// unset, [privacyPolicyUrl] falls back to the backend's own static page.
  static const _privacyPolicyUrlOverride = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
  );

  static String get privacyPolicyUrl => _privacyPolicyUrlOverride.isNotEmpty
      ? _privacyPolicyUrlOverride
      : '$apiOrigin/privacy-policy';
}
