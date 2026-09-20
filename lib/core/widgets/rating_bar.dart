import 'package:flutter/material.dart';

/// 1-5 star rating. Tapping the current rating clears it. Read-only when
/// [onChanged] is null.
class AppRatingBar extends StatelessWidget {
  const AppRatingBar({
    super.key,
    required this.rating,
    this.onChanged,
    this.size = 32,
  });

  final int? rating;
  final ValueChanged<int?>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var star = 1; star <= 5; star++)
          IconButton(
            key: ValueKey('star_$star'),
            padding: EdgeInsets.zero,
            constraints:
                BoxConstraints.tightFor(width: size + 8, height: size + 8),
            iconSize: size,
            onPressed: onChanged == null
                ? null
                : () => onChanged!(rating == star ? null : star),
            icon: Icon(
              star <= (rating ?? 0)
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: star <= (rating ?? 0)
                  ? Colors.amber.shade600
                  : scheme.outline,
            ),
          ),
      ],
    );
  }
}
