import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/responsive.dart';
import '../../widgets/glass_container.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _buildGlassNavbar(context),
    );
  }

  Widget _buildGlassNavbar(BuildContext context) {
    final navItems = <({IconData icon, IconData selectedIcon, String label})>[
      (icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.school_outlined, selectedIcon: Icons.school_rounded, label: 'Academics'),
      (icon: Icons.explore_outlined, selectedIcon: Icons.explore_rounded, label: 'Campus'),
      (icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, label: 'Profile'),
    ];

    return SafeArea(
      minimum: EdgeInsets.fromLTRB(
        Responsive.dp(context, 14),
        0,
        Responsive.dp(context, 14),
        Responsive.isCompact(context) ? 8 : 12,
      ),
      child: GlassContainer(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.dp(context, 8),
          vertical: 8,
        ),
        borderRadius: BorderRadius.circular(28),
        color: AppColors.backgroundSoft,
        borderColor: AppColors.outline,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < navItems.length; i++)
              _buildNavItem(
                context: context,
                index: i,
                icon: navItems[i].icon,
                selectedIcon: navItems[i].selectedIcon,
                label: navItems[i].label,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = navigationShell.currentIndex == index;
    const animDuration = Duration(milliseconds: 300);
    const animCurve = Curves.easeOutCubic;
    final compact = Responsive.isCompact(context);
    final iconSize = Responsive.dp(context, compact ? 19 : 21);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _onNavigate(index);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: compact ? 66 : 76,
        child: AnimatedContainer(
          duration: animDuration,
          curve: animCurve,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.crimson : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: isSelected ? 1.04 : 1,
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected
                      ? AppColors.background
                      : AppColors.white54,
                  size: iconSize,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  color: isSelected ? AppColors.background : AppColors.white54,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: Responsive.sp(context, compact ? 9 : 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNavigate(int index) {
    if (navigationShell.currentIndex == index) {
      return;
    }

    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
