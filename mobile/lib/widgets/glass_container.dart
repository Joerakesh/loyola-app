import 'package:flutter/material.dart';

import 'app_card.dart';

/// Legacy name retained so existing screens share the standard AppCard surface.
@Deprecated('Use AppCard for new UI.')
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
    return AppCard(
      padding: padding,
      radius: borderRadius?.topLeft.x ?? 22,
      color: color,
      borderColor: borderColor,
      onTap: onTap,
      child: child,
    );
  }
}
