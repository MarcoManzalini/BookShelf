import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../domain/entities/reading_status.dart';
import 'reading_status_ui.dart';

/// Reading status as a library rubber stamp.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.tilt = false});

  final ReadingStatus status;

  /// Slightly rotates the stamp, as if pressed by hand.
  final bool tilt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = switch (status) {
      ReadingStatus.wantToRead => scheme.onSurfaceVariant,
      ReadingStatus.reading => scheme.secondary,
      ReadingStatus.read => scheme.tertiary,
    };
    final stamp = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: ink, width: 1.4),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        status.label(context.l10n).toUpperCase(),
        style: AppFonts.label(
          size: 11,
          weight: FontWeight.w700,
          letterSpacing: 1.3,
          color: ink,
        ),
      ),
    );
    return tilt
        ? Transform.rotate(angle: -2 * math.pi / 180, child: stamp)
        : stamp;
  }
}
