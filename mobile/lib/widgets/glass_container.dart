import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius,
    this.color,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = borderRadius ?? BorderRadius.circular(22);
    final fill = color ?? AppColors.glass;

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: r,
        border: Border.all(color: borderColor ?? AppColors.outline),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: r,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
