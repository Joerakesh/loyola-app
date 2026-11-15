import 'package:flutter/material.dart';

/// Single source of truth for the app's visual system.
class AppTheme {
  AppTheme._();

  static const colors = AppPalette();

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: colors.primary,
      secondary: colors.secondary,
      surface: colors.surface,
      error: colors.error,
      onSurface: colors.textPrimary,
      outline: colors.outline,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.background,
      colorScheme: scheme,
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: colors.textPrimary,
        displayColor: colors.textPrimary,
      ),
      visualDensity: VisualDensity.compact,
      splashFactory: InkRipple.splashFactory,
      dividerTheme: DividerThemeData(
        color: colors.outline,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: colors.textPrimary),
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: const Size(48, 50),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        circularTrackColor: colors.overlay,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Semantic color tokens. Screens should consume these through AppTheme.
class AppPalette {
  const AppPalette();

  final Color background = const Color(0xFF0B1014);
  final Color backgroundSoft = const Color(0xFF111920);
  final Color surface = const Color(0xFF18232B);
  final Color outline = const Color(0xFF293942);
  final Color primary = const Color(0xFFB9F36B);
  final Color secondary = const Color(0xFF72E4D2);
  final Color blue = const Color(0xFF65BFFF);
  final Color purple = const Color(0xFFB8A1FF);
  final Color orange = const Color(0xFFFFB86B);
  final Color success = const Color(0xFF72E4D2);
  final Color error = const Color(0xFFFF7C78);
  final Color textPrimary = const Color(0xFFF3F7F4);
  final Color textSecondary = const Color(0xFFCAD5D6);
  final Color textMuted = const Color(0xFF94A5AA);
  final Color textSubtle = const Color(0xFF718187);
  final Color textDisabled = const Color(0xFF5C6D74);
  final Color onPrimary = const Color(0xFF0B1014);
  final Color overlay = const Color(0x33FFFFFF);

  // Compatibility aliases for existing screen code while it is migrated.
  Color get crimson => primary;
  Color get gold => secondary;
  Color get glass => surface;
  Color get green => success;
  Color get red => error;
  Color get white => textPrimary;
  Color get white70 => textSecondary;
  Color get white60 => const Color(0xFFB0BEC1);
  Color get white54 => textMuted;
  Color get white38 => textSubtle;
  Color get white30 => textDisabled;
  Color get white24 => const Color(0xFF4A5B62);
}
