import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// The soft, slowly drifting backdrop painted behind every screen.
///
/// Installed once in `MaterialApp.builder`, so it sits under all routes and
/// keeps animating across navigation instead of restarting per screen.
/// Scaffolds are transparent (see [AppTheme]) so it shows through. Honors
/// the OS "remove animations" setting by holding still.
class AnimatedAppBackground extends StatefulWidget {
  const AnimatedAppBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AnimatedAppBackground> createState() => _AnimatedAppBackgroundState();
}

class _AnimatedAppBackgroundState extends State<AnimatedAppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 28),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(painter: _BackdropPainter(_controller)),
        ),
        // Screens without an AppBar (home, login) still get a legible status bar.
        AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.statusBarStyle,
          child: widget.child,
        ),
      ],
    );
  }
}

class _Blob {
  const _Blob(
    this.color,
    this.radius,
    this.cx,
    this.cy,
    this.ax,
    this.ay,
    this.phase,
  );

  final Color color;

  /// Radius as a fraction of the screen's shorter side.
  final double radius;

  /// Resting center and drift amplitude, as fractions of width/height.
  final double cx, cy, ax, ay;
  final double phase;
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  static const _blobs = [
    _Blob(Color(0x406C4CF0), 0.95, 0.05, 0.08, 0.10, 0.06, 0.0),
    _Blob(Color(0x3329B6F6), 0.80, 0.98, 0.30, 0.08, 0.10, 1.7),
    _Blob(Color(0x30F06CC8), 0.85, 0.12, 0.88, 0.09, 0.07, 3.4),
    _Blob(Color(0x2C1FAE6B), 0.60, 0.90, 0.95, 0.07, 0.06, 4.9),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF7F5FF), AppColors.background, Color(0xFFF3F1FB)],
        ).createShader(rect),
    );

    final t = animation.value * 2 * math.pi;
    final unit = size.shortestSide;
    for (final b in _blobs) {
      final center = Offset(
        size.width * (b.cx + b.ax * math.sin(t + b.phase)),
        size.height * (b.cy + b.ay * math.cos(t * 2 + b.phase)),
      );
      final r = unit * b.radius * (1 + 0.06 * math.sin(t * 3 + b.phase));
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [b.color, b.color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }

    // A few tiny sparkles floating upward, for a sense of life.
    final dot = Paint()..color = AppColors.primary.withValues(alpha: 0.10);
    for (var i = 0; i < 14; i++) {
      final seed = i * 0.6180339887;
      final x = (seed * 7.3 % 1) * size.width + math.sin(t * 2 + i) * 12;
      final y =
          (1 - ((animation.value * 2 + seed) % 1)) * (size.height + 40) - 20;
      canvas.drawCircle(Offset(x, y), 2.0 + (i % 3), dot);
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
