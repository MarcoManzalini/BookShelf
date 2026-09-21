import 'package:flutter/material.dart';

/// Plus Jakarta Sans (geometric, friendly, strong in bold) is the only
/// typeface in the app. It is a variable font: weight is an axis.
abstract final class AppFonts {
  static const family = 'PlusJakartaSans';

  static TextStyle text({
    required double size,
    FontWeight weight = FontWeight.w400,
    FontStyle style = FontStyle.normal,
    double height = 1.4,
    double letterSpacing = 0,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight,
      fontStyle: style,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
    );
  }

  /// Small style for captions, counters and metadata.
  static TextStyle label({
    required double size,
    FontWeight weight = FontWeight.w500,
    double height = 1.3,
    double letterSpacing = 0.1,
    Color? color,
  }) {
    return text(
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
      displayLarge: text(
        size: 52,
        weight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -1.2,
        color: ink,
      ),
      displayMedium: text(
        size: 42,
        weight: FontWeight.w800,
        height: 1.12,
        letterSpacing: -1,
        color: ink,
      ),
      displaySmall: text(
        size: 34,
        weight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.8,
        color: ink,
      ),
      headlineLarge: text(
        size: 30,
        weight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.6,
        color: ink,
      ),
      headlineMedium: text(
        size: 26,
        weight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.5,
        color: ink,
      ),
      headlineSmall: text(
        size: 22,
        weight: FontWeight.w700,
        height: 1.22,
        letterSpacing: -0.3,
        color: ink,
      ),
      titleLarge: text(
        size: 20,
        weight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.3,
        color: ink,
      ),
      titleMedium: text(
        size: 16,
        weight: FontWeight.w700,
        height: 1.3,
        color: ink,
      ),
      titleSmall: text(
        size: 14,
        weight: FontWeight.w700,
        height: 1.3,
        color: ink,
      ),
      bodyLarge: text(size: 16, height: 1.5, color: ink),
      bodyMedium: text(size: 14, height: 1.5, color: ink),
      bodySmall: text(size: 12, height: 1.4, color: scheme.onSurfaceVariant),
      labelLarge: label(size: 14, weight: FontWeight.w700, color: ink),
      labelMedium: label(size: 12.5, weight: FontWeight.w600, color: ink),
      labelSmall: label(size: 11.5, color: scheme.onSurfaceVariant),
    );
  }
}
