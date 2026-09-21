import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(AppColors.lightScheme);
  static ThemeData get dark => _build(AppColors.darkScheme);

  static const _radius = 14.0;

  static ThemeData _build(ColorScheme scheme) {
    final textTheme = AppFonts.textTheme(scheme);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radius),
    );
    const pill = StadiumBorder();
    final hairline = BorderSide(color: scheme.outlineVariant);
    final softShadow =
        Colors.black.withAlpha(scheme.brightness == Brightness.dark ? 90 : 34);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
      fontFamily: AppFonts.family,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkRipple.splashFactory,
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurfaceVariant,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 24),
        titleTextStyle: AppFonts.text(
          size: 18,
          weight: FontWeight.w800,
          height: 1.2,
          letterSpacing: -0.3,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        shadowColor: softShadow,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: shape,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        labelStyle: AppFonts.label(size: 14, color: scheme.onSurfaceVariant),
        floatingLabelStyle: AppFonts.label(
          size: 13,
          weight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        hintStyle: AppFonts.text(
          size: 14,
          color: scheme.onSurfaceVariant.withAlpha(200),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: hairline,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: hairline,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: scheme.onSurface, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: scheme.error, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: pill,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: pill,
          side: BorderSide(color: scheme.outlineVariant, width: 1.4),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: pill,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
      ),
      chipTheme: ChipThemeData(
        shape: pill,
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primary,
        side: BorderSide.none,
        // Resting: soft fill, ink label. Selected: filled with primary (ink
        // in light mode, near-white in dark), so the label flips to onPrimary.
        // The color itself carries the state: the chip resolves it there.
        labelStyle: AppFonts.label(
          size: 12.5,
          weight: FontWeight.w600,
          color: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurface,
          ),
        ),
        showCheckmark: false,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: pill,
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: AppFonts.label(size: 12.5, weight: FontWeight.w700),
          selectedBackgroundColor: scheme.primary,
          selectedForegroundColor: scheme.onPrimary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 26,
            color: selected ? scheme.onSurface : scheme.outline,
          );
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: textTheme.titleLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: AppFonts.text(
          size: 14,
          color: scheme.onInverseSurface,
        ),
        shape: shape,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: scheme.surfaceContainerHigh,
        linearMinHeight: 5,
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 3,
        activeTrackColor: AppColors.accent,
        thumbColor: AppColors.accent,
        inactiveTrackColor: scheme.surfaceContainerHigh,
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: AppFonts.label(
          size: 13,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
