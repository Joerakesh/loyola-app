import 'package:flutter/material.dart';

/// Single source of truth for the app's visual system.
class AppTheme {
  AppTheme._();

  static const background = Color(0xFF0B1014);
  static const backgroundSoft = Color(0xFF111920);
  static const surface = Color(0xFF18232B);
  static const outline = Color(0xFF293942);
  static const primary = Color(0xFFB9F36B);
  static const secondary = Color(0xFF72E4D2);
  static const blue = Color(0xFF65BFFF);
  static const purple = Color(0xFFB8A1FF);
  static const orange = Color(0xFFFFB86B);
  static const success = Color(0xFF72E4D2);
  static const error = Color(0xFFFF7C78);
  static const textPrimary = Color(0xFFF3F7F4);
  static const textSecondary = Color(0xFFCAD5D6);
  static const textMuted = Color(0xFF94A5AA);
  static const textSubtle = Color(0xFF718187);
  static const textDisabled = Color(0xFF5C6D74);
  static const onPrimary = Color(0xFF0B1014);
  static const overlay = Color(0x33FFFFFF);
  static const colors = AppPalette();

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: error,
      onSurface: textPrimary,
      outline: outline,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: scheme,
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      visualDensity: VisualDensity.compact,
      splashFactory: InkRipple.splashFactory,
      dividerTheme: DividerThemeData(
        color: outline,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: const Size(48, 50),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        circularTrackColor: overlay,
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

/// Read-only grouped access to the semantic tokens for existing UI widgets.
class AppPalette {
  const AppPalette();

  final Color background = AppTheme.background;
  final Color backgroundSoft = AppTheme.backgroundSoft;
  final Color surface = AppTheme.surface;
  final Color outline = AppTheme.outline;
  final Color primary = AppTheme.primary;
  final Color secondary = AppTheme.secondary;
  final Color blue = AppTheme.blue;
  final Color purple = AppTheme.purple;
  final Color orange = AppTheme.orange;
  final Color success = AppTheme.success;
  final Color error = AppTheme.error;
  final Color textPrimary = AppTheme.textPrimary;
  final Color textSecondary = AppTheme.textSecondary;
  final Color textMuted = AppTheme.textMuted;
  final Color textSubtle = AppTheme.textSubtle;
  final Color textDisabled = AppTheme.textDisabled;
  final Color onPrimary = AppTheme.onPrimary;
  final Color overlay = AppTheme.overlay;

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
