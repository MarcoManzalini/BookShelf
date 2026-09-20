import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Brand mark: three books on a shelf, the last one leaning.
class BookshelfMark extends StatelessWidget {
  const BookshelfMark({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MarkPainter(
          spines: [scheme.primary, scheme.secondary, AppColors.brass],
          shelf: scheme.onSurface,
          band: scheme.surface,
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.spines, required this.shelf, required this.band});

  final List<Color> spines;
  final Color shelf;
  final Color band;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 72;
    final baseY = size.height - 10 * u;

    final shelfPaint = Paint()..color = shelf;
    canvas.drawRRect(
      RRect.fromLTRBR(
        4 * u,
        baseY,
        size.width - 4 * u,
        baseY + 4 * u,
        Radius.circular(1.5 * u),
      ),
      shelfPaint,
    );

    void book(double x, double w, double h, Color color) {
      final rect = RRect.fromLTRBAndCorners(
        x,
        baseY - h,
        x + w,
        baseY,
        topLeft: Radius.circular(2 * u),
        topRight: Radius.circular(2 * u),
      );
      canvas.drawRRect(rect, Paint()..color = color);
      final bandPaint = Paint()
        ..color = band.withAlpha(150)
        ..strokeWidth = 1.4 * u;
      canvas.drawLine(
        Offset(x + 2 * u, baseY - h + 8 * u),
        Offset(x + w - 2 * u, baseY - h + 8 * u),
        bandPaint,
      );
      canvas.drawLine(
        Offset(x + 2 * u, baseY - h + 11 * u),
        Offset(x + w - 2 * u, baseY - h + 11 * u),
        bandPaint,
      );
    }

    book(10 * u, 14 * u, 46 * u, spines[0]);
    book(26 * u, 12 * u, 38 * u, spines[1]);

    canvas.save();
    canvas.translate(52 * u, baseY);
    canvas.rotate(-14 * math.pi / 180);
    canvas.translate(-52 * u, -baseY);
    book(40 * u, 12 * u, 42 * u, spines[2]);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.spines != spines || old.shelf != shelf || old.band != band;
}
