import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_router.dart';
import '../core/constants/app_colors.dart';
import '../services/auth_provider.dart';
import '../services/cache_warmup.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.authProvider,
    required this.warmup,
  });

  final AuthProvider authProvider;
  final CacheWarmup warmup;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _minimumShowTime = Duration(milliseconds: 2600);

  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _logoScale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();

    _bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final startedAt = DateTime.now();

    // 1. Try to restore the remembered session automatically.
    final loggedIn = await widget.authProvider.autoLogin();

    // 2. While the branding is on screen, prefetch every endpoint so the
    //    rest of the app can render straight from cache. The fetch continues
    //    in the background even if it takes longer than the splash timeout.
    if (loggedIn) {
      await widget.warmup
          .prefetchAll()
          .timeout(
            const Duration(seconds: 6),
            onTimeout: () {},
          );
    }

    // 3. Keep the splash visible for at least the minimum duration.
    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < _minimumShowTime) {
      await Future.delayed(_minimumShowTime - elapsed);
    }

    if (!mounted) return;

    context.go(loggedIn ? AppRoutes.home : AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A0A0A),
              Color(0xFF0F0E17),
              Color(0xFF16060A),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              right: -70,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x338B0000),
                ),
              ),
            ),
            Positioned(
              bottom: -110,
              left: -60,
              child: Container(
                width: 340,
                height: 340,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x22007AFF),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _logoScale,
                    child: _buildLogo(),
                  ),
                  const SizedBox(height: 40),
                  FadeTransition(
                    opacity: _textFade,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'LOYOLA COLLEGE',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'C H E N N A I',
                          style: TextStyle(
                            color: Color(0xFFFFB4A2),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 8,
                          ),
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Autonomous · Affiliated to University of Madras',
                          style: TextStyle(
                            color: AppColors.white38,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 56),
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.crimson,
                      backgroundColor: Color(0x1FFFFFFF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.white.withValues(alpha: 0.16),
            AppColors.white.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.28),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.crimson.withValues(alpha: 0.45),
            blurRadius: 42,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/loyola_logo.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.school_rounded,
            size: 56,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}