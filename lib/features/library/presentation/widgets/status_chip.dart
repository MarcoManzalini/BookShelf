import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../domain/entities/reading_status.dart';
import 'reading_status_ui.dart';

/// Reading status as a small rounded tag.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final ReadingStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      ReadingStatus.wantToRead => (
          scheme.surfaceContainerHigh,
          scheme.onSurfaceVariant,
        ),
      ReadingStatus.reading => (
          scheme.secondaryContainer,
          AppColors.accentDeep
        ),
      ReadingStatus.read => (scheme.primary, scheme.onPrimary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label(context.l10n),
        style: AppFonts.label(
          size: 12,
          weight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}
