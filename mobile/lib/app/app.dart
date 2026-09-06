import 'package:flutter/material.dart';
import 'app_router.dart';

class LoyolaApp extends StatelessWidget {
  const LoyolaApp({super.key, required this.appRouter});

  final AppRouter appRouter;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loyola ERP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B0000)),
      ),
      initialRoute: AppRouter.login,
      onGenerateRoute: appRouter.generateRoute,
    );
  }
}
