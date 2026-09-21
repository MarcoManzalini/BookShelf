import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Horizontal bars for the most common subjects, scaled to the biggest one.
class SubjectBars extends StatelessWidget {
  const SubjectBars({super.key, required this.subjects});

  final List<MapEntry<String, int>> subjects;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxCount = subjects.fold<int>(1, (m, e) => e.value > m ? e.value : m);
    return Column(
      children: [
        for (final entry in subjects)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    entry.key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.text(size: 13, color: scheme.onSurface),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: entry.value / maxCount,
                      minHeight: 10,
                      color: AppColors.accent,
                      backgroundColor: scheme.surfaceContainerHigh,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${entry.value}',
                  style: AppFonts.label(
                    size: 12,
                    weight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
