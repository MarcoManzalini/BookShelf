import 'package:flutter/material.dart';

/// Palette of a reading room: bottle-green ink, bookmark oxblood, brass
/// fittings, walnut shelves and ledger paper with a faint green cast.
abstract final class AppColors {
  // Fixed brand tones (used by the ribbon, shelf and cloth covers).
  static const brass = Color(0xFFB08D3C);
  static const brassLight = Color(0xFFE3BE6A);
  static const oxblood = Color(0xFF7A1F2B);
  static const bottleGreen = Color(0xFF1F3D33);
  static const walnutLight = Color(0xFF4A3A2C);
  static const walnutDark = Color(0xFF6B5644);

  /// Cloth colors for books that have no cover image.
  static const clothCovers = <Color>[
    Color(0xFF1F3D33),
    Color(0xFF6E2130),
    Color(0xFF22364F),
    Color(0xFF5A4326),
    Color(0xFF40283F),
    Color(0xFF2F4A4A),
  ];

  static const lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: bottleGreen,
    onPrimary: Color(0xFFF6F6EE),
    primaryContainer: Color(0xFFD3DFD2),
    onPrimaryContainer: Color(0xFF10251D),
    secondary: oxblood,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFEBD3D4),
    onSecondaryContainer: Color(0xFF45101A),
    tertiary: Color(0xFF7D5F1B),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFEFE0B8),
    onTertiaryContainer: Color(0xFF382A06),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFEEEFE6),
    onSurface: Color(0xFF17211C),
    onSurfaceVariant: Color(0xFF4E5A52),
    outline: Color(0xFF8A948B),
    outlineVariant: Color(0xFFC5CABD),
    surfaceContainerLowest: Color(0xFFFBFBF6),
    surfaceContainerLow: Color(0xFFF6F6EE),
    surfaceContainer: Color(0xFFE7E8DE),
    surfaceContainerHigh: Color(0xFFE0E2D7),
    surfaceContainerHighest: Color(0xFFD9DBCF),
    inverseSurface: Color(0xFF1F2B25),
    onInverseSurface: Color(0xFFEEEFE6),
    inversePrimary: brassLight,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static const darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: brassLight,
    onPrimary: Color(0xFF2A1F05),
    primaryContainer: Color(0xFF2C4A3E),
    onPrimaryContainer: Color(0xFFD5E5D6),
    secondary: Color(0xFFE0707F),
    onSecondary: Color(0xFF3A0A12),
    secondaryContainer: Color(0xFF5A1A26),
    onSecondaryContainer: Color(0xFFF6D3D8),
    tertiary: Color(0xFFA9C7B0),
    onTertiary: Color(0xFF10251D),
    tertiaryContainer: Color(0xFF24382F),
    onTertiaryContainer: Color(0xFFD5E5D6),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    surface: Color(0xFF0F1A15),
    onSurface: Color(0xFFE8E9DF),
    onSurfaceVariant: Color(0xFFB0BAB1),
    outline: Color(0xFF79857C),
    outlineVariant: Color(0xFF33443B),
    surfaceContainerLowest: Color(0xFF0B130F),
    surfaceContainerLow: Color(0xFF15231D),
    surfaceContainer: Color(0xFF1A2A23),
    surfaceContainerHigh: Color(0xFF20322A),
    surfaceContainerHighest: Color(0xFF283A31),
    inverseSurface: Color(0xFFE8E9DF),
    onInverseSurface: Color(0xFF1F2B25),
    inversePrimary: bottleGreen,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );
}
