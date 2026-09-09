/// App-wide configuration, overridable at build/run time with --dart-define.
///
/// Android emulators can't reach the host machine's `localhost`; `10.0.2.2` is
/// the emulator's alias for it. Override for a physical device or iOS
/// simulator, e.g.:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api/v1
class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.8.169:8000/api/v1',
  );

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
