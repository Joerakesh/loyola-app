import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'app_router.dart';

class LoyolaApp extends StatelessWidget {
  const LoyolaApp({super.key, required this.appRouter});

  final AppRouter appRouter;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Loyola ERP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: appRouter.router,
    );
  }
}