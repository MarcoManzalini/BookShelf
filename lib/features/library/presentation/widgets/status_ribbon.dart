import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/reading_status.dart';

/// Bookmark ribbon hanging from the top edge of a cover. Books that are only
/// wanted have no ribbon: there is nothing to mark yet.
class StatusRibbon extends StatelessWidget {
  const StatusRibbon({super.key, required this.status, this.width = 14});

  final ReadingStatus status;
  final double width;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ReadingStatus.wantToRead => null,
      ReadingStatus.reading => Theme.of(context).colorScheme.secondary,
      ReadingStatus.read => AppColors.brass,
    };
    if (color == null) return const SizedBox.shrink();
    return CustomPaint(
      size: Size(width, width * 2),
      painter: _RibbonPainter(color),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  _RibbonPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height - size.width * 0.4)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawShadow(path, Colors.black, 2, false);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawLine(
      Offset(size.width * 0.22, 0),
      Offset(size.width * 0.22, size.height * 0.82),
      Paint()
        ..color = Colors.white.withAlpha(50)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_RibbonPainter old) => old.color != color;
}
