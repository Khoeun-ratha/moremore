import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../l10n/l10n_extension.dart';
import '../theme/app_theme.dart';

/// Embeds a YouTube lesson video via the official iFrame Player API.
class YoutubeLessonPlayer extends StatefulWidget {
  const YoutubeLessonPlayer({super.key, required this.url});

  final String url;

  @override
  State<YoutubeLessonPlayer> createState() => _YoutubeLessonPlayerState();
}

class _YoutubeLessonPlayerState extends State<YoutubeLessonPlayer> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayerController.convertUrlToId(widget.url);
    if (videoId != null) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(showFullscreenButton: true),
      );
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: AppColors.surfaceHigh,
          child: Center(
            child: Text(
              context.tr('couldNotLoadVideo'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }
    return YoutubePlayer(controller: controller, aspectRatio: 16 / 9);
  }
}
