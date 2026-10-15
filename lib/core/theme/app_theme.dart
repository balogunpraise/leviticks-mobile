import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';

/// Light/dark themes mirroring the web app's Tailwind setup:
/// white/gray-900 surfaces, gray-200/gray-700 borders, `primary` accent.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondaryLight,
      surface: Colors.white,
      error: AppColors.rose,
    );

    return _base(
      scheme: scheme,
      scaffoldBackground: AppColors.shadedLight,
      cardColor: Colors.white,
      borderColor: AppColors.gray200,
      textPrimary: AppColors.gray900,
      textMuted: AppColors.gray500,
      brightness: Brightness.light,
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondaryDark,
      surface: AppColors.gray900,
      error: AppColors.rose,
    );

    return _base(
      scheme: scheme,
      scaffoldBackground: AppColors.gray950,
      cardColor: AppColors.gray900,
      borderColor: AppColors.gray700,
      textPrimary: Colors.white,
      textMuted: AppColors.gray400,
      brightness: Brightness.dark,
    );
  }

  static ThemeData _base({
    required ColorScheme scheme,
    required Color scaffoldBackground,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textMuted,
    required Brightness brightness,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      cardColor: cardColor,
      dividerColor: borderColor,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: cardColor,
        foregroundColor: textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: borderColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light ? AppColors.gray50 : AppColors.gray800,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      dividerTheme: DividerThemeData(color: borderColor, space: 1),
      textTheme: base0TextTheme(textPrimary, textMuted),
      splashFactory: NoSplash.splashFactory,
    );

    return base;
  }

  static TextTheme base0TextTheme(Color primary, Color muted) {
    return TextTheme(
      headlineMedium: TextStyle(color: primary, fontWeight: FontWeight.w800, fontSize: 24),
      titleLarge: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 18),
      titleMedium: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 15),
      bodyLarge: TextStyle(color: primary, fontSize: 14),
      bodyMedium: TextStyle(color: primary, fontSize: 13),
      bodySmall: TextStyle(color: muted, fontSize: 12),
      labelSmall: TextStyle(color: muted, fontSize: 11),
    );
  }
}
