import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/responsive.dart';

const _dockRadius = 34.0;
const _dockPadding = 6.0;
const _itemGap = 4.0;
const _motion = Duration(milliseconds: 420);
const _curve = Curves.easeOutCubic;

typedef _NavItem = ({IconData icon, IconData selectedIcon, String label});

const List<_NavItem> _navItems = [
  (icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home'),
  (icon: Icons.school_outlined, selectedIcon: Icons.school_rounded, label: 'Academics'),
  (icon: Icons.explore_outlined, selectedIcon: Icons.explore_rounded, label: 'Campus'),
  (icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, label: 'Profile'),
];

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _buildDock(context),
    );
  }

  Widget _buildDock(BuildContext context) {
    final compact = Responsive.isCompact(context);
    const outer = BorderRadius.all(Radius.circular(_dockRadius));
    const inner = BorderRadius.all(Radius.circular(_dockRadius - 1));

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background.withValues(alpha: 0),
            AppColors.background.withValues(alpha: 0.82),
          ],
        ),
      ),
      child: SafeArea(
        minimum: EdgeInsets.fromLTRB(
          Responsive.dp(context, 18),
          18,
          Responsive.dp(context, 18),
          compact ? 8 : 12,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: outer,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 32,
                spreadRadius: -4,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              borderRadius: outer,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.34),
                  Colors.white.withValues(alpha: 0.06),
                ],
              ),
            ),
            child: ClipRRect(
              borderRadius: inner,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  height: compact ? 62 : 66,
                  padding: const EdgeInsets.all(_dockPadding),
                  color: AppColors.backgroundSoft.withValues(alpha: 0.62),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final selectedIndex = navigationShell.currentIndex;
                      final itemCount = _navItems.length;
                      final gapWidth = (itemCount - 1) * _itemGap;
                      final availableWidth = constraints.maxWidth - gapWidth;
                      final collapsedWidth = compact ? 46.0 : 52.0;
                      final selectedWidth = availableWidth -
                          ((itemCount - 1) * collapsedWidth);

                      return Row(
                        children: [
                          for (var i = 0; i < itemCount; i++) ...[
                            if (i > 0) const SizedBox(width: _itemGap),
                            _DockItem(
                              item: _navItems[i],
                              selected: selectedIndex == i,
                              width: selectedIndex == i
                                  ? selectedWidth
                                  : collapsedWidth,
                              onTap: () => _onNavigate(i),
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

  void _onNavigate(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
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
    final accent = AppColors.crimson;
    final accentLight = Color.lerp(accent, Colors.white, 0.22)!;
    final contentColor = selected ? AppColors.background : AppColors.white54;

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
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: _motion,
            curve: _curve,
            width: widget.width,
            height: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: selected ? 10 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: selected
                    ? [accentLight, accent]
                    : [Colors.transparent, Colors.transparent],
              ),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? accent.withValues(alpha: 0.38)
                      : Colors.transparent,
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    selected ? widget.item.selectedIcon : widget.item.icon,
                    key: ValueKey(selected),
                    color: contentColor,
                    size: 24,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: AnimatedOpacity(
                      opacity: 1,
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        widget.item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: contentColor,
                          fontSize: Responsive.sp(context, 13),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
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
