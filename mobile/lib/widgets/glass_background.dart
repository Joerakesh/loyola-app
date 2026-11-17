import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme/theme_provider.dart';

class GlassGlow {
  const GlassGlow({this.top, this.left, this.right, this.bottom, required this.size, required this.color});
  final double? top, left, right, bottom;
  final double size;
  final Color color;
}

class GlassBackground extends StatefulWidget {
  const GlassBackground({super.key, required this.child, this.glows = const []});
  final Widget child;
  final List<GlassGlow> glows;

  @override
  State<GlassBackground> createState() => _GlassBackgroundState();
}

class _GlassBackgroundState extends State<GlassBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();

  @override
  void dispose() { _motion.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<ThemeProvider>().selected;
    final theme = selected;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color.lerp(theme.background, theme.surfaceVariant, .55)!, theme.background, Color.lerp(theme.background, theme.surface, .35)!],
          stops: const [0, .55, 1],
        ),
      ),
      child: Stack(fit: StackFit.expand, children: [
        if (theme.id == 'spider')
          Positioned.fill(child: AnimatedBuilder(
            animation: _motion,
            builder: (_, __) => CustomPaint(painter: _WebPatternPainter(
              color: theme.secondary.withValues(alpha: .19),
              progress: _motion.value,
              accent: theme.primary.withValues(alpha: .10),
            )),
          ))
        if (theme.id == 'spider')
          Positioned.fill(child: IgnorePointer(child: SvgPicture.asset('assets/themes/spider_web_overlay.svg', fit: BoxFit.cover)))
        else
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _AmbientPatternPainter(
            color: theme.primary.withValues(alpha: .055),
          )))),
        for (final glow in widget.glows)
          Positioned(top: glow.top, left: glow.left, right: glow.right, bottom: glow.bottom,
            child: Container(width: glow.size, height: glow.size,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [glow.color, glow.color.withValues(alpha: 0)])))),
        Positioned.fill(child: widget.child),
      ]),
    );
  }
}

class _WebPatternPainter extends CustomPainter {
  const _WebPatternPainter({required this.color, required this.progress, required this.accent});
  final Color color, accent;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final anchor = Offset(size.width * .94, size.height * .02);
    final radius = size.longestSide * .88;
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1;
    // Radial silk strands from a top-right anchor.
    for (var i=0;i<=14;i++) {
      final angle = (i / 14) * 1.45 + .12;
      final end = anchor + Offset(-radius * (1 - i / 19), radius * (i / 14));
      canvas.drawLine(anchor, end, paint);
    }
    // Curved concentric web rings.
    for (var ring=1;ring<=11;ring++) {
      final r = radius * ring / 11;
      final path = Path();
      for (var i=0;i<=80;i++) {
        final t = i/80;
        final a = .12 + t*1.45;
        final wobble = 1 + .025 * (ring.isEven ? 1 : -1);
        final point = anchor + Offset(-r * (1-t) * wobble, r * t * wobble);
        if (i==0) path.moveTo(point.dx, point.dy); else path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint..color = color.withValues(alpha: .55));
    }
    final pulse = .5 + .5 * (progress < .5 ? progress*2 : (1-progress)*2);
    final glowPaint = Paint()..color = accent.withValues(alpha: .35 + pulse*.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(anchor + Offset(-size.width*.23, size.height*.23), 34 + pulse*12, glowPaint);
    // A moving strand highlight gives the background a living, restrained motion.
    final x = size.width * (.15 + .7 * progress);
    final highlight = Paint()..color = color.withValues(alpha: .28)..strokeWidth = 1.6;
    canvas.drawLine(Offset(x, 0), Offset(x-size.width*.18, size.height*.28), highlight);
  }
  @override
  bool shouldRepaint(covariant _WebPatternPainter old) => old.progress != progress || old.color != color;
}

class _AmbientPatternPainter extends CustomPainter {
  const _AmbientPatternPainter({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1;
    for (var i=0;i<7;i++) {
      final rect = Rect.fromCircle(center: Offset(size.width * (i.isEven ? 0.12 : 0.88), size.height * (i.isEven ? 0.18 : 0.78)), radius: 34.0+i*23);
      canvas.drawCircle(rect.center, rect.width/2, paint);
    }
  }
  @override
  bool shouldRepaint(covariant _AmbientPatternPainter old) => old.color != color;
}
