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
      appBar: AppBar(
        title: const Text('Choose your theme'),
        actions: [
          TextButton(
            onPressed: () => context.read<ThemeProvider>().reset(),
            child: const Text('Reset'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          Text('Make Loyola feel like yours',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Choose a look. Your selection is saved on this device.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(height: 20),
          for (final theme in LoyolaThemes.all) ...[
            _ThemeOption(
              theme: theme,
              selected: theme.id == selectedId,
              onTap: () => context.read<ThemeProvider>().select(theme.id),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          Text(
            'Theme artwork and branded character assets can be added separately when properly licensed. These built-in themes use original colour palettes.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.theme, required this.selected, required this.onTap});
  final LoyolaTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final outline = selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline.withValues(alpha: .35);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: outline, width: selected ? 2 : 1),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Row(
            children: [
              _ThemePreview(theme: theme),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(theme.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(theme.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Row(children: [
                      _Dot(color: theme.primary), const SizedBox(width: 5),
                      _Dot(color: theme.secondary), const SizedBox(width: 5),
                      _Dot(color: theme.background), const SizedBox(width: 8),
                      Text(theme.isLight ? 'Light' : 'Dark', style: Theme.of(context).textTheme.labelSmall),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.theme});
  final LoyolaTheme theme;

  @override
  Widget build(BuildContext context) => Container(
    width: 82,
    height: 94,
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      color: theme.background,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: theme.muted.withValues(alpha: .25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 8, width: 34, decoration: BoxDecoration(color: theme.primary, borderRadius: BorderRadius.circular(8))),
        const SizedBox(height: 7),
        Container(
          height: 25,
          decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(7)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(margin: const EdgeInsets.all(5), height: 5, width: 28,
              decoration: BoxDecoration(color: theme.secondary, borderRadius: BorderRadius.circular(5))),
          ),
        ),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: Container(height: 23, decoration: BoxDecoration(color: theme.surfaceVariant, borderRadius: BorderRadius.circular(6)))),
          const SizedBox(width: 5),
          Expanded(child: Container(height: 23, decoration: BoxDecoration(color: theme.primary.withValues(alpha: .8), borderRadius: BorderRadius.circular(6)))),
        ]),
        const Spacer(),
        Container(height: 4, width: 48, decoration: BoxDecoration(color: theme.muted, borderRadius: BorderRadius.circular(4))),
      ],
    ),
  );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 11, height: 11,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
