import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.crimson,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: scheme,
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
        iconTheme: IconThemeData(color: AppColors.white),
        titleTextStyle: TextStyle(
          color: AppColors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.white,
      ),
    );
  }
}