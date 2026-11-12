import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_router.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/responsive.dart';
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
  static const Duration _minimumShowTime = Duration(milliseconds: 650);

  late final AnimationController _entranceController;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _logoScale = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    );

    _textFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _entranceController.forward();
    _bootstrap();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final startedAt = DateTime.now();

    var loggedIn = false;
    try {
      loggedIn = await widget.authProvider.autoLogin();
    } catch (e) {
      debugPrint('Auto-login error: $e');
      loggedIn = false;
    }

    if (loggedIn) {
      unawaited(
        widget.warmup.prefetchAll().catchError((error) {
          debugPrint('Cache warmup error: $error');
        }),
      );
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
            colors: [
              Color(0xFF111920),
              AppColors.background,
              Color(0xFF0B1014),
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final compact = w < 360 || h < 560;
            final orbSize = (w * 0.55).clamp(220.0, 420.0);
            final logoSize = compact
                ? (w * 0.30).clamp(84.0, 130.0)
                : 130.0;

            return Stack(
              children: [
                // Ambient Orbs (positioned off-screen corners)
                Positioned(
                  top: -orbSize * 0.35,
                  right: -orbSize * 0.25,
                  child: Container(
                    width: orbSize,
                    height: orbSize,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x1FB9F36B),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -orbSize * 0.38,
                  left: -orbSize * 0.30,
                  child: Container(
                    width: orbSize * 1.2,
                    height: orbSize * 1.2,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x1472E4D2),
                    ),
                  ),
                ),

                // Foreground Content (no full-screen blur - expensive on GPU)
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _logoScale,
                          child: Container(
                            width: logoSize,
                            height: logoSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.glass,
                              border: Border.all(
                                color: AppColors.crimson,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.crimson.withValues(
                                    alpha: 0.16,
                                  ),
                                  blurRadius: 22,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/loyola_logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      Icons.school_rounded,
                                      size: logoSize * 0.43,
                                      color: AppColors.white,
                                    ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? h * 0.04 : 48),
                        FadeTransition(
                          opacity: _textFade,
                          child: SlideTransition(
                            position: _textSlide,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'LOYOLA COLLEGE',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: Responsive.sp(context, 26),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'C H E N N A I',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.gold,
                                    fontSize: Responsive.sp(context, 13),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 8,
                                  ),
                                ),
                                SizedBox(height: Responsive.dp(context, 14)),
                                Text(
                                  'Autonomous · Affiliated to University of Madras',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.white38,
                                    fontSize: Responsive.sp(context, 11),
                                    letterSpacing: 0.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? h * 0.03 : 50),
                        FadeTransition(
                          opacity: _textFade,
                          child: SizedBox(
                            width: 76,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: const LinearProgressIndicator(
                                minHeight: 4,
                                backgroundColor: AppColors.outline,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
