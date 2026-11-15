import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Backwards-compatible aliases. New UI code should use AppTheme tokens.
@Deprecated('Use AppTheme color tokens instead.')
class AppColors {
  AppColors._();

  static const background = AppTheme.background;
  static const backgroundSoft = AppTheme.backgroundSoft;
  static const glass = AppTheme.surface;
  static const outline = AppTheme.outline;
  static const surface = AppTheme.surface;
  static const crimson = AppTheme.primary;
  static const gold = AppTheme.secondary;
  static const blue = AppTheme.blue;
  static const purple = AppTheme.purple;
  static const orange = AppTheme.orange;
  static const green = AppTheme.success;
  static const red = AppTheme.error;
  static const white = AppTheme.textPrimary;
  static const white70 = AppTheme.textSecondary;
  static const white60 = Color(0xFFB0BEC1);
  static const white54 = AppTheme.textMuted;
  static const white38 = AppTheme.textSubtle;
  static const white30 = AppTheme.textDisabled;
  static const white24 = Color(0xFF4A5B62);
}
