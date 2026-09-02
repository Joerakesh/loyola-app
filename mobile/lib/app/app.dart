import 'package:flutter/material.dart';

import '../features/auth/presentation/login_screen.dart';

class LoyolaApp extends StatelessWidget {
  const LoyolaApp({super.key});

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
      home: const LoginScreen(),
    );
  }
}
