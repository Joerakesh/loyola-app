import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/theme_provider.dart';
import 'app_router.dart';

class LoyolaApp extends StatelessWidget {
  const LoyolaApp({super.key, required this.appRouter});

  final AppRouter appRouter;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return MaterialApp.router(
      title: 'Loyola ERP',
      debugShowCheckedModeBanner: false,
      theme: theme.themeData,
      routerConfig: appRouter.router,
    );
  }
}