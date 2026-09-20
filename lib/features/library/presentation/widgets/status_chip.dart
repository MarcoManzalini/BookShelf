import 'package:flutter/material.dart';

import '../../../../core/utils/l10n_extension.dart';
import '../../domain/entities/reading_status.dart';
import 'reading_status_ui.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final ReadingStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      ReadingStatus.wantToRead => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
        ),
      ReadingStatus.reading => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
        ),
      ReadingStatus.read => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            status.label(context.l10n),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
