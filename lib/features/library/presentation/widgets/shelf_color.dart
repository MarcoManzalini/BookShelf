import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A shelf keeps the same colour everywhere, derived from its name.
Color shelfColor(String name) {
  final seed = name
      .toLowerCase()
      .codeUnits
      .fold<int>(7, (a, b) => (a * 31 + b) & 0x7fffffff);
  return AppColors.posterCovers[seed % AppColors.posterCovers.length];
}

/// Readable text colour on top of [shelfColor].
Color onShelfColor(Color shelf) =>
    ThemeData.estimateBrightnessForColor(shelf) == Brightness.dark
        ? Colors.white
        : AppColors.ink;
