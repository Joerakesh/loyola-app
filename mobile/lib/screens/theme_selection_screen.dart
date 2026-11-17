import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/theme_provider.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedId = context.watch<ThemeProvider>().selected.id;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Choose your theme'), actions: [
        TextButton(onPressed: () => context.read<ThemeProvider>().reset(), child: const Text('Reset')),
      ]),
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 32), children: [
        Text('Make Loyola feel like yours', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('Select a theme to instantly preview its colours, background and visual effects.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
        const SizedBox(height: 20),
        for (final theme in LoyolaThemes.all) ...[
          _ThemeOption(theme: theme, selected: theme.id == selectedId, onTap: () => context.read<ThemeProvider>().select(theme.id)),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        Text('Themes use original visual effects and colour treatments. Character artwork can be added separately when licensed.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant, height: 1.45)),
      ]),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.theme, required this.selected, required this.onTap});
  final LoyolaTheme theme; final bool selected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final outline = selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline.withValues(alpha: .35);
    return Semantics(button: true, selected: selected, child: InkWell(
      borderRadius: BorderRadius.circular(20), onTap: onTap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 300), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: outline, width: selected ? 2 : 1), color: Theme.of(context).colorScheme.surface),
        child: Row(children: [
          _ThemePreview(theme: theme), const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(theme.name, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(theme.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Row(children: [_Dot(color: theme.primary), const SizedBox(width: 5), _Dot(color: theme.secondary), const SizedBox(width: 5), _Dot(color: theme.background), const SizedBox(width: 8), Text(theme.isLight ? 'Light' : 'Dark', style: Theme.of(context).textTheme.labelSmall)]),
          ])),
          const SizedBox(width: 8),
          Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant),
        ]),
      ),
    ));
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.theme});
  final LoyolaTheme theme;
  @override
  Widget build(BuildContext context) => Container(width: 82, height: 94, clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(color: theme.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.muted.withValues(alpha: .25))),
    child: Stack(children: [
      if (theme.id == 'spider') Positioned.fill(child: CustomPaint(painter: _MiniWebPainter(theme.secondary.withValues(alpha: .45)))),
      Padding(padding: const EdgeInsets.all(7), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 8, width: 34, decoration: BoxDecoration(color: theme.primary, borderRadius: BorderRadius.circular(8))),
        const SizedBox(height: 7),
        Container(height: 25, decoration: BoxDecoration(color: theme.surface.withValues(alpha: .94), borderRadius: BorderRadius.circular(7)), child: Align(alignment: Alignment.centerLeft, child: Container(margin: const EdgeInsets.all(5), height: 5, width: 28, decoration: BoxDecoration(color: theme.secondary, borderRadius: BorderRadius.circular(5))))),
        const SizedBox(height: 6),
        Row(children: [Expanded(child: Container(height: 23, decoration: BoxDecoration(color: theme.surfaceVariant.withValues(alpha: .95), borderRadius: BorderRadius.circular(6)))), const SizedBox(width: 5), Expanded(child: Container(height: 23, decoration: BoxDecoration(color: theme.primary.withValues(alpha: .8), borderRadius: BorderRadius.circular(6))))]),
        const Spacer(), Container(height: 4, width: 48, decoration: BoxDecoration(color: theme.muted, borderRadius: BorderRadius.circular(4))),
      ])),
    ]),
  );
}

class _MiniWebPainter extends CustomPainter {
  const _MiniWebPainter(this.color); final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = .7;
    final c = Offset(size.width, 0);
    for (var i=1;i<=7;i++) canvas.drawLine(c, Offset(size.width-i*14, i*13.5), paint);
    for (var r=1;r<=6;r++) canvas.drawArc(Rect.fromCircle(center: c, radius: r*12), 1.57, 1.57, false, paint);
  }
  @override
  bool shouldRepaint(covariant _MiniWebPainter old) => old.color != color;
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color}); final Color color;
  @override
  Widget build(BuildContext context) => Container(width: 11, height: 11, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
