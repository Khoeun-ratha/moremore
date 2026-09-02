import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../l10n/l10n_extension.dart';
import '../theme/app_theme.dart';

/// Streams the lesson's video from the backend's Range-enabled /media
/// endpoint, so seeking works without any extra client-side code.
class LessonVideoPlayer extends StatefulWidget {
  const LessonVideoPlayer({super.key, required this.url});

  final String url;

  @override
  State<LessonVideoPlayer> createState() => _LessonVideoPlayerState();
}

class _LessonVideoPlayerState extends State<LessonVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _videoController = controller;
        _chewieController = ChewieController(
          videoPlayerController: controller,
          aspectRatio: controller.value.aspectRatio,
          autoPlay: false,
          looping: false,
          materialProgressColors: ChewieProgressColors(
            playedColor: AppColors.primary,
            handleColor: AppColors.primaryHigh,
            bufferedColor: AppColors.surfaceHigh,
            backgroundColor: AppColors.border,
          ),
        );
      });
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
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
    final chewie = _chewieController;
    if (chewie == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: AppColors.surfaceHigh,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return AspectRatio(
      aspectRatio: chewie.aspectRatio ?? 16 / 9,
      child: Chewie(controller: chewie),
    );
  }
}
