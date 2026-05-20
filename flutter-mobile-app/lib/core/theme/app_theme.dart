import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.orange,
      onPrimary: AppColors.prussian,
      primaryContainer: AppColors.dusk,
      onPrimaryContainer: AppColors.white,
      primaryFixed: AppColors.orange,
      primaryFixedDim: AppColors.orange,
      onPrimaryFixed: AppColors.prussian,
      onPrimaryFixedVariant: AppColors.prussian,
      secondary: AppColors.dusk,
      onSecondary: AppColors.white,
      secondaryContainer: AppColors.prussian,
      onSecondaryContainer: AppColors.alabaster,
      secondaryFixed: AppColors.dusk,
      secondaryFixedDim: AppColors.dusk,
      onSecondaryFixed: AppColors.white,
      onSecondaryFixedVariant: AppColors.alabaster,
      tertiary: AppColors.green,
      onTertiary: AppColors.white,
      tertiaryContainer: AppColors.dusk,
      onTertiaryContainer: AppColors.alabaster,
      tertiaryFixed: AppColors.green,
      tertiaryFixedDim: AppColors.green,
      onTertiaryFixed: AppColors.white,
      onTertiaryFixedVariant: AppColors.alabaster,
      error: AppColors.tangerine,
      onError: AppColors.white,
      errorContainer: AppColors.tangerine,
      onErrorContainer: AppColors.white,
      surface: AppColors.prussian,
      onSurface: AppColors.white,
      surfaceDim: AppColors.prussian,
      surfaceBright: AppColors.dusk,
      surfaceContainerLowest: AppColors.prussian,
      surfaceContainerLow: AppColors.prussian,
      surfaceContainer: AppColors.dusk,
      surfaceContainerHigh: AppColors.dusk,
      surfaceContainerHighest: AppColors.dusk,
      onSurfaceVariant: AppColors.silver,
      outline: AppColors.dusk,
      outlineVariant: AppColors.dusk,
      shadow: AppColors.prussian,
      scrim: AppColors.prussian,
      inverseSurface: AppColors.alabaster,
      onInverseSurface: AppColors.prussian,
      inversePrimary: AppColors.orange,
      surfaceTint: AppColors.orange,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.midnight,
      fontFamily: 'Roboto',
      textTheme: _textTheme,
      primaryTextTheme: _textTheme,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: AppColors.midnight,
        foregroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.white,
          fontFamily: 'Roboto',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.orange,
        selectionColor: AppColors.orange.withAlpha(60),
        selectionHandleColor: AppColors.orange,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.ink,
        labelStyle: const TextStyle(
          color: AppColors.silver,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        hintStyle: const TextStyle(
          color: AppColors.silver,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        prefixIconColor: AppColors.silver,
        suffixIconColor: AppColors.silver,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.white.withAlpha(20)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.white.withAlpha(20)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.orange),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.tangerine),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.tangerine),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.ink,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.prussian,
          disabledBackgroundColor: AppColors.dusk,
          disabledForegroundColor: AppColors.silver,
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.white),
      dividerTheme: DividerThemeData(
        color: AppColors.white.withAlpha(16),
        thickness: 1,
      ),
    );
  }

  static ThemeData get light => dark;

  static const _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Roboto',
      color: AppColors.white,
      fontSize: 32,
      fontWeight: FontWeight.w900,
      letterSpacing: 0,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Roboto',
      color: AppColors.white,
      fontSize: 28,
      fontWeight: FontWeight.w900,
      letterSpacing: 0,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Roboto',
      color: AppColors.white,
      fontSize: 22,
      fontWeight: FontWeight.w900,
      letterSpacing: 0,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Roboto',
      color: AppColors.white,
      fontSize: 18,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Roboto',
      color: AppColors.white,
      fontSize: 15,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Roboto',
      color: AppColors.white,
      fontSize: 13,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Roboto',
      color: AppColors.alabaster,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Roboto',
      color: AppColors.alabaster,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Roboto',
      color: AppColors.silver,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Roboto',
      color: AppColors.prussian,
      fontSize: 14,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Roboto',
      color: AppColors.alabaster,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Roboto',
      color: AppColors.silver,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
  );
}
