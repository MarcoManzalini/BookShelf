import 'package:flutter/material.dart';

/// Clean white canvas, near-black ink and a single warm orange accent; the
/// colour comes from the book covers themselves.
abstract final class AppColors {
  static const ink = Color(0xFF16161A);
  static const accent = Color(0xFFFF8A3D);
  static const accentDeep = Color(0xFFE8600F);

  /// Flat poster colours for books that have no cover image.
  static const posterCovers = <Color>[
    Color(0xFFE5433B),
    Color(0xFFF5C22B),
    Color(0xFF2E55B8),
    Color(0xFFFF8A3D),
    Color(0xFF1F9D8B),
    Color(0xFF7C4DBA),
    Color(0xFF16161A),
  ];

  static const lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: ink,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF1F1F4),
    onPrimaryContainer: ink,
    secondary: accent,
    onSecondary: ink,
    secondaryContainer: Color(0xFFFFEBDC),
    onSecondaryContainer: Color(0xFF5A2405),
    tertiary: accentDeep,
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFEBDC),
    onTertiaryContainer: Color(0xFF5A2405),
    error: Color(0xFFD92D20),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    onSurface: ink,
    onSurfaceVariant: Color(0xFF8A8A94),
    outline: Color(0xFFB4B4BD),
    outlineVariant: Color(0xFFEAEAEE),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFAFAFB),
    surfaceContainer: Color(0xFFF5F5F7),
    surfaceContainerHigh: Color(0xFFEFEFF2),
    surfaceContainerHighest: Color(0xFFE8E8EC),
    inverseSurface: Color(0xFF232328),
    onInverseSurface: Color(0xFFF5F5F7),
    inversePrimary: accent,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static const darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFF4F4F6),
    onPrimary: ink,
    primaryContainer: Color(0xFF2A2A30),
    onPrimaryContainer: Color(0xFFF4F4F6),
    secondary: Color(0xFFFF9A55),
    onSecondary: ink,
    secondaryContainer: Color(0xFF4A2C17),
    onSecondaryContainer: Color(0xFFFFE3CF),
    tertiary: Color(0xFFFFA96B),
    onTertiary: ink,
    tertiaryContainer: Color(0xFF4A2C17),
    onTertiaryContainer: Color(0xFFFFE3CF),
    error: Color(0xFFFF8A80),
    onError: Color(0xFF3B0906),
    surface: Color(0xFF111114),
    onSurface: Color(0xFFF1F1F4),
    onSurfaceVariant: Color(0xFF9D9DA8),
    outline: Color(0xFF6E6E79),
    outlineVariant: Color(0xFF2B2B31),
    surfaceContainerLowest: Color(0xFF0C0C0F),
    surfaceContainerLow: Color(0xFF17171B),
    surfaceContainer: Color(0xFF1C1C21),
    surfaceContainerHigh: Color(0xFF222227),
    surfaceContainerHighest: Color(0xFF2A2A30),
    inverseSurface: Color(0xFFF1F1F4),
    onInverseSurface: Color(0xFF232328),
    inversePrimary: ink,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );
}
