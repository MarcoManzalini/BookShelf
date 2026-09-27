import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Minimal vertical bar chart: one bar per value with a small label below.
/// The bar at [highlight] (e.g. today, this month) is drawn in the accent
/// colour, the others in a soft neutral.
class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.values,
    required this.labels,
    this.highlight,
    this.height = 120,
    this.onBarTap,
  }) : assert(values.length == labels.length);

  final List<int> values;
  final List<String> labels;
  final int? highlight;
  final double height;

  /// Called with the tapped bar's index, when the chart is interactive.
  final void Function(int index)? onBarTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxValue = values.fold<int>(0, (m, v) => v > m ? v : m);
    return SizedBox(
      height: height + 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBarTap == null ? null : () => onBarTap!(i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (values[i] > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '${values[i]}',
                          style: AppFonts.label(
                            size: 10,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      height: maxValue == 0
                          ? 3
                          : 3 + (height - 24) * values[i] / maxValue,
                      decoration: BoxDecoration(
                        color: i == highlight
                            ? AppColors.accent
                            : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      maxLines: 1,
                      style: AppFonts.label(
                        size: 10,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
