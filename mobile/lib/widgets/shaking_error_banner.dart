import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A prominent error banner that shakes and fades in as soon as it mounts —
/// much harder to miss than a line of small red text. Give it a fresh
/// `ValueKey(message)` from the caller so a new/changed message (e.g. a
/// second failed login attempt) always remounts and replays the animation.
class ShakingErrorBanner extends StatefulWidget {
  const ShakingErrorBanner({super.key, required this.message});

  final String message;

  @override
  State<ShakingErrorBanner> createState() => _ShakingErrorBannerState();
}

class _ShakingErrorBannerState extends State<ShakingErrorBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  late final Animation<double> _shakeOffset =
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
        TweenSequenceItem(tween: Tween(begin: -10.0, end: 8.0), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 1),
        TweenSequenceItem(tween: Tween(begin: -6.0, end: 4.0), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
      ]).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7)),
      );

  late final Animation<double> _fadeIn = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _fadeIn.value,
        child: Transform.translate(
          offset: Offset(_shakeOffset.value, 0),
          child: child,
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: AppColors.danger,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
