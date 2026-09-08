import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

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
    with TickerProviderStateMixin {
  static const Duration _minimumShowTime = Duration(milliseconds: 2800);

  // Entrance Animations
  late final AnimationController _entranceController;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  // Continuous Breathing Animation
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Setup Entrance Choreography
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _logoScale = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    );

    _textFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    // 2. Setup Ambient Glow (Breathing Effect)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Start entrance
    _entranceController.forward();
    _bootstrap();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final startedAt = DateTime.now();

    final loggedIn = await widget.authProvider.autoLogin();

    if (loggedIn) {
      try {
        await widget.warmup.prefetchAll().timeout(const Duration(seconds: 6));
      } on TimeoutException catch (_) {
        debugPrint('Cache warmup timed out, proceeding to app.');
      } catch (e) {
        debugPrint('Warmup error: $e');
      }
    }

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
            colors: [Color(0xFF120B10), Color(0xFF0C0A14), Color(0xFF0B0F12)],
          ),
        ),
        child: Stack(
          children: [
            // Ambient Orbs
            Positioned(
              top: -120,
              right: -60,
              child: Container(
                width: 380,
                height: 380,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x1F8B0000),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -80,
              child: Container(
                width: 450,
                height: 450,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x10007AFF),
                ),
              ),
            ),

            // True Glassmorphism Blur Layer
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: const SizedBox(),
              ),
            ),

            // Foreground Content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _logoScale,
                    child: AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) => _buildLogo(),
                    ),
                  ),
                  const SizedBox(height: 48),
                  FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'LOYOLA COLLEGE',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'C H E N N A I',
                            style: TextStyle(
                              color: Color(0xFFFFB4A2),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 10,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Autonomous · Affiliated to University of Madras',
                            style: TextStyle(
                              color: AppColors.white38,
                              fontSize: 12,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Integrated Custom Lottie Animation
                  FadeTransition(
                    opacity: _textFade,
                    child: SizedBox(
                      width: 160,
                      height: 160,
                      child: Lottie.asset(
                        'assets/animations/loading.json',
                        fit: BoxFit.contain,
                        // This dynamically colors your custom JSON to match the theme
                        delegates: LottieDelegates(
                          values: [
                            ValueDelegate.color(
                              const [
                                '**',
                              ], // Targets all shapes/strokes in the JSON
                              value: AppColors.crimson,
                            ),
                          ],
                        ),
                      ),
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
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.white.withValues(alpha: 0.15),
            AppColors.white.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.crimson.withValues(alpha: _glowAnimation.value),
            blurRadius: 50,
            spreadRadius: 2 + (_glowAnimation.value * 10),
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
