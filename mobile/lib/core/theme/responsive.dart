import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static const double _designWidth = 390;

  static double width(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double height(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static double textScale(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1.0);

  static bool isCompact(BuildContext context) => width(context) < 360;

  static bool isWide(BuildContext context) => width(context) >= 600;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  static double sp(BuildContext context, double size) {
    final w = width(context);
    final scaled = size * (w / _designWidth).clamp(0.85, 1.25);
    return MediaQuery.textScalerOf(context).scale(scaled);
  }

  static double dp(BuildContext context, double size) {
    final w = width(context);
    return size * (w / _designWidth).clamp(0.9, 1.15);
  }

  static EdgeInsets screenPadding(BuildContext context) {
    final w = width(context);
    final horizontal = (w * 0.05).clamp(16.0, 28.0);
    return EdgeInsets.symmetric(
      horizontal: horizontal,
      vertical: horizontal.isFinite ? 0 : 0,
    );
  }

  static double cardGap(BuildContext context) {
    return isCompact(context) ? 12 : 14;
  }
}