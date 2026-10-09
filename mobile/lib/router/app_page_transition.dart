import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

/// The app's one standard page transition, applied to every route so
/// navigation feels consistent instead of relying on each platform's
/// differing default animation.
///
/// Screens are transparent over the shared animated background, so this is a
/// fade-through: the outgoing page fades away (and recedes slightly) before
/// the incoming one rises in — the two never visibly overlap.
CustomTransitionPage<T> buildPageWithTransition<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.routeDuration,
    reverseTransitionDuration: AppMotion.routeDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        fadeThroughTransition(animation, secondaryAnimation, child),
  );
}

Widget fadeThroughTransition(
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final incoming = CurvedAnimation(
    parent: animation,
    curve: const Interval(0.35, 1, curve: AppMotion.curve),
  );
  final outgoing = CurvedAnimation(
    parent: secondaryAnimation,
    curve: const Interval(0, 0.45, curve: Curves.easeIn),
  );
  return FadeTransition(
    opacity: ReverseAnimation(outgoing),
    child: ScaleTransition(
      scale: Tween<double>(begin: 1, end: 0.97).animate(outgoing),
      child: FadeTransition(
        opacity: incoming,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(incoming),
          child: child,
        ),
      ),
    ),
  );
}

/// The same fade-through for routes go_router builds with a default page
/// (the bottom-nav shell), installed via the theme's pageTransitionsTheme.
class FadeThroughPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeThroughPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => fadeThroughTransition(animation, secondaryAnimation, child);
}
