import 'package:flutter/material.dart';

/// Literata (made for long-form reading) is the only typeface in the app.
abstract final class AppFonts {
  static const serifFamily = 'Literata';

  static TextStyle serif({
    required double size,
    FontWeight weight = FontWeight.w400,
    FontStyle style = FontStyle.normal,
    double height = 1.4,
    double letterSpacing = 0,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: serifFamily,
      fontSize: size,
      fontWeight: weight,
      fontStyle: style,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
      // Literata is a variable font: weight and optical size are axes.
      fontVariations: [
        FontVariation('wght', weight.value.toDouble()),
        FontVariation('opsz', size.clamp(7, 72).toDouble()),
      ],
    );
  }

  /// Small, letter-spaced style for labels, stamps and catalogue data.
  static TextStyle label({
    required double size,
    FontWeight weight = FontWeight.w400,
    double height = 1.3,
    double letterSpacing = 0.4,
    Color? color,
  }) {
    return serif(
      size: size,
      weight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextTheme textTheme(ColorScheme scheme) {
    final ink = scheme.onSurface;
    return TextTheme(
      displayLarge:
          serif(size: 56, weight: FontWeight.w700, height: 1.1, color: ink),
      displayMedium:
          serif(size: 44, weight: FontWeight.w700, height: 1.12, color: ink),
      displaySmall:
          serif(size: 36, weight: FontWeight.w700, height: 1.15, color: ink),
      headlineLarge:
          serif(size: 32, weight: FontWeight.w700, height: 1.2, color: ink),
      headlineMedium:
          serif(size: 28, weight: FontWeight.w700, height: 1.2, color: ink),
      headlineSmall:
          serif(size: 24, weight: FontWeight.w700, height: 1.22, color: ink),
      titleLarge:
          serif(size: 22, weight: FontWeight.w700, height: 1.25, color: ink),
      titleMedium:
          serif(size: 17, weight: FontWeight.w600, height: 1.3, color: ink),
      titleSmall:
          serif(size: 15, weight: FontWeight.w600, height: 1.3, color: ink),
      bodyLarge: serif(size: 16, height: 1.5, color: ink),
      bodyMedium: serif(size: 14.5, height: 1.5, color: ink),
      bodySmall: serif(size: 12.5, height: 1.4, color: scheme.onSurfaceVariant),
      labelLarge: label(
        size: 14,
        weight: FontWeight.w700,
        letterSpacing: 0.6,
        color: ink,
      ),
      labelMedium: label(
        size: 12.5,
        weight: FontWeight.w700,
        letterSpacing: 0.5,
        color: ink,
      ),
      labelSmall:
          label(size: 11.5, letterSpacing: 0.4, color: scheme.onSurfaceVariant),
    );
  }
}
