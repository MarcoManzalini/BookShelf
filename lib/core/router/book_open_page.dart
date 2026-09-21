import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/book_cover.dart';
import '../widgets/book_open_target.dart';

/// Details page that opens like a book: the tapped cover flies to the centre,
/// swings open on its spine to reveal a blank page, and the page grows to fill
/// the screen as the details appear on it. Without a known starting cover it
/// falls back to a quick fade.
class BookOpenPage<T> extends CustomTransitionPage<T> {
  BookOpenPage({
    required LocalKey super.key,
    required super.child,
    required BookOpenOrigin? origin,
  }) : super(
          transitionDuration:
              origin == null ? _fadeDuration : BookOpenTransition.duration,
          reverseTransitionDuration: origin == null
              ? _fadeDuration
              : BookOpenTransition.reverseDuration,
          transitionsBuilder: (context, animation, secondary, child) =>
              origin == null
                  ? FadeTransition(opacity: animation, child: child)
                  : BookOpenTransition(
                      animation: animation,
                      origin: origin,
                      child: child,
                    ),
        );

  static const _fadeDuration = Duration(milliseconds: 240);

  /// The origin is captured once per page: go_router may rebuild the page
  /// (e.g. on an auth refresh) long after the tap, when nothing is pending.
  static final _origins = <LocalKey, BookOpenOrigin?>{};

  static BookOpenPage<T> forState<T>(
    GoRouterState state, {
    required Widget child,
  }) {
    final key = state.pageKey;
    final origin = _origins.putIfAbsent(key, BookOpenTarget.take);
    return BookOpenPage<T>(key: key, origin: origin, child: child);
  }
}

class BookOpenTransition extends StatelessWidget {
  const BookOpenTransition({
    super.key,
    required this.animation,
    required this.origin,
    required this.child,
  });

  final Animation<double> animation;
  final BookOpenOrigin origin;
  final Widget child;

  static const duration = Duration(milliseconds: 1150);

  /// Popping plays the animation backwards: the page shrinks, the cover swings
  /// shut on its spine, then flies back to the shelf.
  static const reverseDuration = Duration(milliseconds: 850);

  /// How far the cover swings open, in radians (~150°).
  static const _openAngle = 2.6;

  @override
  Widget build(BuildContext context) {
    final paper = Theme.of(context).colorScheme.surface;
    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = Offset.zero & constraints.biggest;
        final target = _targetRect(screen, origin.rect);
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, page) {
            final t = animation.value;
            double phase(double from, double to, [Curve? curve]) =>
                (curve ?? Curves.easeInOutCubic)
                    .transform(((t - from) / (to - from)).clamp(0.0, 1.0));

            final fly = phase(0, 0.34);
            final open = phase(0.30, 0.66);
            final expand = phase(0.58, 1);
            final content = phase(0.78, 1, Curves.easeOut);
            final coverOpacity = 1 - phase(0.62, 0.85);
            final scrim = phase(0, 0.3);
            // The blank page only exists once the cover has landed on it.
            final sheetOpacity = phase(0.30, 0.34, Curves.linear);

            final sheet = Rect.lerp(target, screen, expand)!;
            final coverRect = Rect.lerp(origin.rect, target, fly)!;

            return IgnorePointer(
              ignoring: animation.status != AnimationStatus.completed,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: Colors.black.withValues(alpha: 0.5 * scrim),
                  ),
                  // The page: blank paper at first, the details fade in on it
                  // as it grows to the full screen.
                  Opacity(
                    opacity: sheetOpacity,
                    child: ClipPath(
                      clipper: _RectClipper(sheet, 6 * (1 - expand)),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(color: paper),
                          Opacity(opacity: content, child: page),
                          Positioned(
                            left: sheet.left,
                            top: sheet.top,
                            width: 28 * (1 - expand),
                            height: sheet.height,
                            child: const _GutterShadow(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (coverOpacity > 0)
                    Positioned.fromRect(
                      rect: coverRect,
                      child: Opacity(
                        opacity: coverOpacity,
                        child: _OpeningCover(
                          origin: origin,
                          angle: open * _openAngle,
                          endpaper: paper,
                          lifted: fly,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Where the cover comes to rest before opening: centred, as large as fits.
  static Rect _targetRect(Rect screen, Rect from) {
    final aspect =
        from.width <= 0 || from.height <= 0 ? 2 / 3 : from.width / from.height;
    final maxWidth = screen.width * 0.66;
    final maxHeight = screen.height * 0.5;
    final height = math.min(maxHeight, maxWidth / aspect);
    final width = height * aspect;
    return Rect.fromCenter(
      center: Offset(screen.center.dx, screen.height * 0.44),
      width: width,
      height: height,
    );
  }
}

/// The front cover, hinged on its left edge. Past 90° the viewer sees the
/// inside of the board (the endpaper) instead of the artwork.
class _OpeningCover extends StatelessWidget {
  const _OpeningCover({
    required this.origin,
    required this.angle,
    required this.endpaper,
    required this.lifted,
  });

  final BookOpenOrigin origin;
  final double angle;
  final Color endpaper;

  /// 0-1: how far the cover has been lifted off the shelf (drives its shadow).
  final double lifted;

  @override
  Widget build(BuildContext context) {
    final showingBack = angle > math.pi / 2;
    final shade = math.sin(angle).clamp(0.0, 1.0);

    final Widget face = showingBack
        ? DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(endpaper, Colors.black, 0.18)!,
                  endpaper,
                ],
              ),
            ),
          )
        : Stack(
            fit: StackFit.expand,
            children: [
              BookCover(
                url: origin.url,
                title: origin.title,
                author: origin.author,
                size: origin.size,
                borderRadius: 0,
              ),
              // The cover darkens as it turns away from the light.
              ColoredBox(color: Colors.black.withValues(alpha: 0.4 * shade)),
            ],
          );

    return Transform(
      alignment: Alignment.centerLeft,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        // Positive angle swings the free edge toward the viewer (opening);
        // with this perspective, negative would push it away like a closing.
        ..rotateY(angle),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35 * lifted),
              blurRadius: 28,
              offset: const Offset(6, 14),
            ),
          ],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(3), child: face),
      ),
    );
  }
}

/// Soft shade along the spine of the page, where the book curves down.
class _GutterShadow extends StatelessWidget {
  const _GutterShadow();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0x26000000), Color(0x00000000)],
        ),
      ),
    );
  }
}

class _RectClipper extends CustomClipper<Path> {
  _RectClipper(this.rect, this.radius);

  final Rect rect;
  final double radius;

  @override
  Path getClip(Size size) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

  @override
  bool shouldReclip(_RectClipper oldClipper) =>
      oldClipper.rect != rect || oldClipper.radius != radius;
}
