import 'dart:ui';
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
        color: Color(0x558B0000),
      ),
      GlassGlow(
        bottom: -60,
        right: -40,
        size: 300,
        color: Color(0x44007AFF),
      ),
    ],
    this.blur = 40,
  });

  final Widget child;
  final List<GlassGlow> glows;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
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
                  color: glow.color,
                ),
              ),
            ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}