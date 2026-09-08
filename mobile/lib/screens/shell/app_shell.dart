import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        icon: Icons.leaderboard_outlined,
        selectedIcon: Icons.leaderboard_rounded,
        label: 'Marks',
      ),
      (
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: 'Profile',
      ),
    ];

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        borderRadius: BorderRadius.circular(36),
        blur: 30, // Slightly increased blur for a deeper glass effect
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
    const animDuration = Duration(milliseconds: 350);
    const animCurve =
        Curves.easeOutCubic; // Gives that liquid, smooth deceleration

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact(); // Adds a premium tactile feel
        _onNavigate(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: animDuration,
        curve: animCurve,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.white.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Icon Swap Animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isSelected ? selectedIcon : icon,
                key: ValueKey<bool>(
                  isSelected,
                ), // Triggers the switcher animation
                color: isSelected ? AppColors.white : AppColors.white38,
                size: 22,
              ),
            ),

            // 2. Fluid Width Expansion for Text
            ClipRRect(
              child: AnimatedSize(
                duration: animDuration,
                curve: animCurve,
                child: isSelected
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      )
                    // The empty box keeps the height consistent when collapsed
                    : const SizedBox(width: 0, height: 20),
              ),
            ),
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
