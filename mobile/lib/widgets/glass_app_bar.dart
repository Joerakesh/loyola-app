import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.bottomPadding = false,
  });

  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool bottomPadding;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: preferredSize,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            top: 8,
            left: showBackButton ? 8 : 20,
            right: 8,
            bottom: bottomPadding ? 8 : 0,
          ),
          child: Row(
            children: [
              if (showBackButton) ...[
                BackButton(color: AppColors.white),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...?actions,
            ],
          ),
        ),
      ),
    );
  }
}