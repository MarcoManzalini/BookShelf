import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Dimmed camera view with a bright viewfinder cut-out, corner brackets and a
/// sweeping line while the camera is looking for a code.
class ScanOverlay extends StatefulWidget {
  const ScanOverlay({super.key, required this.active});

  /// Whether the scan line sweeps (the camera is looking for a code).
  final bool active;

  /// Viewfinder size for a given screen width: wide, like a barcode.
  static Rect windowFor(Size size) {
    final width = (size.width * 0.8).clamp(0.0, 340.0);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.38),
      width: width,
      height: width * 0.62,
    );
  }

  @override
  State<ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<ScanOverlay>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(ScanOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) return;
    if (widget.active) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final window = ScanOverlay.windowFor(constraints.biggest);
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              size: constraints.biggest,
              painter: _OverlayPainter(
                window: window,
                line: widget.active ? _controller.value : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  _OverlayPainter({required this.window, required this.line});

  final Rect window;

  /// 0-1 position of the scan line, or null when it is hidden.
  final double? line;

  static const _radius = Radius.circular(18);

  @override
  void paint(Canvas canvas, Size size) {
    final hole = RRect.fromRectAndRadius(window, _radius);
    final scrim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(hole),
    );
    canvas.drawPath(scrim, Paint()..color = Colors.black.withAlpha(140));

    final bracket = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const arm = 30.0;
    final r = _radius.x;
    for (final corner in [
      (window.topLeft, 1.0, 1.0),
      (window.topRight, -1.0, 1.0),
      (window.bottomLeft, 1.0, -1.0),
      (window.bottomRight, -1.0, -1.0),
    ]) {
      final (origin, dx, dy) = corner;
      final path = Path()
        ..moveTo(origin.dx + dx * arm, origin.dy)
        ..lineTo(origin.dx + dx * r, origin.dy)
        ..quadraticBezierTo(
          origin.dx,
          origin.dy,
          origin.dx,
          origin.dy + dy * r,
        )
        ..lineTo(origin.dx, origin.dy + dy * arm);
      canvas.drawPath(path, bracket);
    }

    final y = line;
    if (y != null) {
      final ly = window.top + 14 + (window.height - 28) * y;
      canvas.drawLine(
        Offset(window.left + 14, ly),
        Offset(window.right - 14, ly),
        Paint()
          ..color = AppColors.accent.withAlpha(220)
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_OverlayPainter old) =>
      old.window != window || old.line != line;
}
