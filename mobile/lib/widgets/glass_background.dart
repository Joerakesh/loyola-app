import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class GlassGlow {
  const GlassGlow({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;
}

class GlassBackground extends StatelessWidget {
  const GlassBackground({
    super.key,
    required this.child,
    this.glows = const [
      GlassGlow(
        top: -80,
        left: -40,
        size: 280,
        color: Color(0x1FB9F36B),
      ),
      GlassGlow(
        bottom: -60,
        right: -40,
        size: 300,
        color: Color(0x1872E4D2),
      ),
    ],
  });

  final Widget child;
  final List<GlassGlow> glows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111920), AppColors.background, Color(0xFF0B1014)],
          stops: [0, .52, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final glow in glows)
            Positioned(
              top: glow.top,
              left: glow.left,
              right: glow.right,
              bottom: glow.bottom,
              child: Container(
                width: glow.size,
                height: glow.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [glow.color, glow.color.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          // Keep ambient lighting simple so scrolling stays lightweight.
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
