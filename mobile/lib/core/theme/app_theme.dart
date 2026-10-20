import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Loyola's District-inspired visual system: editorial hierarchy, deep surfaces,
/// restrained violet highlights, and the college's crimson brand accent.
class AppTheme {
  AppTheme._();

  static const Color _canvas = Color(0xFF101014);
  static const Color _surface = Color(0xFF1A1A21);
  static const Color _surfaceRaised = Color(0xFF22222B);
  static const Color _outline = Color(0xFF30303A);
  static const Color _accent = Color(0xFFB7A2FF);

  static ThemeData dark() {
    final scheme = const ColorScheme(
      brightness: Brightness.dark,
      primary: _accent,
      onPrimary: Color(0xFF211742),
      secondary: AppColors.crimson,
      onSecondary: Colors.white,
      error: Color(0xFFFF7777),
      onError: Color(0xFF3D0909),
      surface: _surface,
      onSurface: Color(0xFFF7F5FC),
      surfaceContainerLowest: _canvas,
      surfaceContainerLow: _surface,
      surfaceContainer: _surfaceRaised,
      surfaceContainerHigh: Color(0xFF2A2A34),
      surfaceContainerHighest: Color(0xFF343440),
      onSurfaceVariant: Color(0xFFB5B2C1),
      outline: _outline,
      outlineVariant: Color(0xFF292933),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFF7F5FC),
      onInverseSurface: _canvas,
      inversePrimary: Color(0xFF6650A4),
      primaryContainer: Color(0xFF332A4F),
      onPrimaryContainer: Color(0xFFE9DFFF),
      secondaryContainer: Color(0xFF482126),
      onSecondaryContainer: Color(0xFFFFDADD),
      tertiary: Color(0xFF91D9C3),
      onTertiary: Color(0xFF07382D),
      tertiaryContainer: Color(0xFF174E42),
      onTertiaryContainer: Color(0xFFB5F3E0),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _canvas,
      colorScheme: scheme,
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: _outline, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: _outline,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFFF7F5FC)),
        titleTextStyle: TextStyle(
          color: Color(0xFFF7F5FC),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _accent,
      ),
    );
  }
}
