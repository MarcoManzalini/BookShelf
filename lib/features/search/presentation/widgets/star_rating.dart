import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Read-only five-star display with half-star precision.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.value, this.size = 13});

  /// 0-5.
  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final empty = Theme.of(context).colorScheme.outlineVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            switch (value - i) {
              >= 0.75 => Icons.star_rounded,
              >= 0.25 => Icons.star_half_rounded,
              _ => Icons.star_rounded,
            },
            size: size,
            color: value - i >= 0.25 ? AppColors.accent : empty,
          ),
      ],
    );
  }
}
