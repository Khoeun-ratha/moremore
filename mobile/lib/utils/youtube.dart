final RegExp _youtubeHostPattern = RegExp(
  r'^https?://(www\.|m\.)?(youtube\.com|youtu\.be)/',
  caseSensitive: false,
);

/// Whether [url] points at a YouTube watch page/short link rather than a
/// self-hosted media file.
bool isYoutubeUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  return _youtubeHostPattern.hasMatch(url);
}
