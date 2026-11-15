import '../theme/app_theme.dart';

/// Backwards-compatible aliases. New UI code should use AppTheme.colors.
@Deprecated('Use AppTheme.colors instead.')
class AppColors {
  AppColors._();

  static const background = AppTheme.colors.background;
  static const backgroundSoft = AppTheme.colors.backgroundSoft;
  static const glass = AppTheme.colors.surface;
  static const outline = AppTheme.colors.outline;
  static const surface = AppTheme.colors.surface;
  static const crimson = AppTheme.colors.primary;
  static const gold = AppTheme.colors.secondary;
  static const blue = AppTheme.colors.blue;
  static const purple = AppTheme.colors.purple;
  static const orange = AppTheme.colors.orange;
  static const green = AppTheme.colors.success;
  static const red = AppTheme.colors.error;
  static const white = AppTheme.colors.textPrimary;
  static const white70 = AppTheme.colors.textSecondary;
  static const white60 = Color(0xFFB0BEC1);
  static const white54 = AppTheme.colors.textMuted;
  static const white38 = AppTheme.colors.textSubtle;
  static const white30 = AppTheme.colors.textDisabled;
  static const white24 = Color(0xFF4A5B62);
}
