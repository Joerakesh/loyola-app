import 'package:flutter/material.dart';

import '../core/theme/loyola_design.dart';

/// Reusable low-noise surface for dashboards, lists, and summary panels.
class LoyolaSurface extends StatelessWidget {
  const LoyolaSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(LoyolaDesign.space5),
    this.onTap,
    this.backgroundColor,
    this.radius = LoyolaDesign.radiusLarge,
    this.border = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double radius;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: border
          ? const BorderSide(color: LoyolaDesign.outline, width: 1)
          : BorderSide.none,
    );

    return Material(
      color: backgroundColor ?? LoyolaDesign.surface,
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

/// Consistent heading + optional supporting copy for content sections.
class LoyolaSectionHeading extends StatelessWidget {
  const LoyolaSectionHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: LoyolaDesign.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
