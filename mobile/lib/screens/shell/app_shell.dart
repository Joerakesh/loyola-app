import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
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
      (
        icon: Icons.grid_view_rounded,
        selectedIcon: Icons.grid_view_rounded,
        label: 'Home',
      ),
      (
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month_rounded,
        label: 'Attendance',
      ),
      (
        icon: Icons.menu_book_outlined,
        selectedIcon: Icons.menu_book_rounded,
        label: 'Subjects',
      ),
      (
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: 'Profile',
      ),
    ];

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        borderRadius: BorderRadius.circular(36),
        blur: 24,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < navItems.length; i++)
              _buildNavItem(
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
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = navigationShell.currentIndex == index;

    return GestureDetector(
      onTap: () => _onNavigate(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.white.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? AppColors.white : AppColors.white38,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ],
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