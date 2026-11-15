import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';

const _dockRadius = 34.0;
const _dockPadding = 6.0;
const _itemGap = 4.0;
const _motion = Duration(milliseconds: 420);
const _curve = Curves.easeOutCubic;

typedef _NavItem = ({IconData icon, IconData selectedIcon, String label});

const List<_NavItem> _navItems = [
  (icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home'),
  (
    icon: Icons.school_outlined,
    selectedIcon: Icons.school_rounded,
    label: 'Academics',
  ),
  (
    icon: Icons.explore_outlined,
    selectedIcon: Icons.explore_rounded,
    label: 'Campus',
  ),
  (
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
    label: 'Profile',
  ),
  // (icon: Icons.settings_outlined, selectedIcon: Icons.settings_rounded, label: 'Settings'),
];

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: navigationShell.currentIndex == 4
          ? null
          : _buildDock(context),
    );
  }

  Widget _buildDock(BuildContext context) {
    final compact = Responsive.isCompact(context);
    const outer = BorderRadius.all(Radius.circular(_dockRadius));
    const inner = BorderRadius.all(Radius.circular(_dockRadius - 1));

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppTheme.background.withValues(alpha: 0),
        AppTheme.background.withValues(alpha: .82),
      ],
    );

    final shadow = BoxShadow(
      color: Colors.black.withValues(alpha: .35),
      blurRadius: 32,
      spreadRadius: -4,
      offset: const Offset(0, 14),
    );

    final borderGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha: .34),
        Colors.white.withValues(alpha: .06),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(
        minimum: EdgeInsets.fromLTRB(
          Responsive.dp(context, 12),
          18,
          Responsive.dp(context, 12),
          compact ? 8 : 12,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(borderRadius: outer, boxShadow: [shadow]),
          child: Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              borderRadius: outer,
              gradient: borderGradient,
            ),
            child: ClipRRect(
              borderRadius: inner,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  height: compact ? 62 : 66,
                  padding: const EdgeInsets.all(_dockPadding),
                  color: AppTheme.backgroundSoft.withValues(alpha: .62),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final selected = navigationShell.currentIndex;
                      final count = _navItems.length;
                      final gap = (count - 1) * _itemGap;
                      final available = constraints.maxWidth - gap;
                      final collapsed = compact ? 38.0 : 42.0;
                      final selectedWidth =
                          available - ((count - 1) * collapsed);

                      return Row(
                        children: [
                          for (var i = 0; i < count; i++) ...[
                            if (i > 0) const SizedBox(width: _itemGap),
                            _DockItem(
                              item: _navItems[i],
                              selected: selected == i,
                              width: selected == i ? selectedWidth : collapsed,
                              onTap: () => navigationShell.goBranch(
                                i,
                                initialLocation: i == selected,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatefulWidget {
  const _DockItem({
    required this.item,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  @override
  State<_DockItem> createState() => _DockItemState();
}

class _DockItemState extends State<_DockItem> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final accent = AppTheme.crimson;
    final light = Color.lerp(accent, Colors.white, .22)!;
    final content = selected ? AppTheme.background : AppTheme.white54;

    return Semantics(
      button: true,
      selected: selected,
      label: widget.item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down ? .97 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: _motion,
            curve: _curve,
            width: widget.width,
            height: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: selected ? 8 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: selected
                    ? [light, accent]
                    : [Colors.transparent, Colors.transparent],
              ),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? accent.withValues(alpha: .38)
                      : Colors.transparent,
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? widget.item.selectedIcon : widget.item.icon,
                  color: content,
                  size: 22,
                ),
                if (selected) ...[
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      widget.item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(
                        color: content,
                        fontSize: Responsive.sp(context, 11),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
