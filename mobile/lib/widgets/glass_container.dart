import 'package:flutter/material.dart';

import '../core/theme/loyola_design.dart';

/// Kept under its existing name to avoid breaking current screen imports.
///
/// The surface is intentionally solid rather than blur-heavy: it is easier to
/// read, more consistent across screens, and cheaper to paint while scrolling.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius,
    @Deprecated('Surfaces no longer apply backdrop blur.') this.blur = 12,
    this.color,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  /// Retained for source compatibility with existing call sites.
  @Deprecated('Surfaces no longer apply backdrop blur.')
  final double blur;

  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(LoyolaDesign.radiusLarge);
    final shape = RoundedRectangleBorder(
      borderRadius: radius,
      side: BorderSide(
        color: borderColor ?? LoyolaDesign.outline,
        width: 1,
      ),
    );

    return Material(
      color: color ?? LoyolaDesign.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
