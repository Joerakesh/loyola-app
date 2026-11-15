import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.bottomPadding = false,
  });

  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
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
          top: 6,
            left: showBackButton ? 8 : 20,
            right: 8,
            bottom: bottomPadding ? 8 : 0,
          ),
          child: Row(
            children: [
              if (showBackButton) ...[
                BackButton(color: AppTheme.white, onPressed: onBackPressed),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
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
