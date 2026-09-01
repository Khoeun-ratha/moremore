import '../config.dart';

/// Resolves a backend-relative media path (e.g. "/media/videos/x.mp4") to an
/// absolute URL. Mirrors admin/src/utils/media.ts.
String mediaUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (RegExp(r'^https?://').hasMatch(path)) return path;
  return '${AppConfig.apiOrigin}$path';
}
