import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../app/app_router.dart';
import '../core/theme/app_theme.dart';
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
    with SingleTickerProviderStateMixin {
  // Long enough for the entrance to finish before we navigate.
  static const Duration _minimumShowTime = Duration(milliseconds: 1100);

  // The college's own typographic voice for the wordmark and motto.
  static const _serif = TextStyle(
    fontFamily: 'serif',
    fontFamilyFallback: ['Georgia', 'Times New Roman'],
  );

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  // One orchestrated sequence: light blooms, crest settles, name, motto.
  late final Animation<double> _bloom = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, .6, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _crest = CurvedAnimation(
    parent: _c,
    curve: const Interval(.08, .55, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _name = CurvedAnimation(
    parent: _c,
    curve: const Interval(.40, .80, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _motto = CurvedAnimation(
    parent: _c,
    curve: const Interval(.60, 1, curve: Curves.easeOut),
  );

  bool _started = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    _bootstrap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Respect the system "reduce motion" setting.
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // BOOTSTRAP (same logic as before)
  // ---------------------------------------------------------------------------
  Future<void> _bootstrap() async {
    final start = DateTime.now();
    final logged = await widget.authProvider.autoLogin();

    if (logged && !widget.authProvider.requiresErpSetup) {
      unawaited(
        widget.warmup.prefetchAll().catchError((error) {
          debugPrint('Cache warmup error: $error');
        }),
      );
    }

    final elapsed = DateTime.now().difference(start);
    if (elapsed < _minimumShowTime) {
      await Future.delayed(_minimumShowTime - elapsed);
    }

    if (!mounted) return;

    final destination = !logged
        ? AppRoutes.login
        : widget.authProvider.requiresErpSetup
        ? AppRoutes.erpSetup
        : AppRoutes.home;
    context.go(destination);
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final compact = w < 360 || h < 560;
          final crest = compact ? (w * .28).clamp(76.0, 110.0) : 116.0;
          final bloom = (w * 1.25).clamp(320.0, 620.0);

          return AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              return Stack(
                children: [
                  // The one light source: "Luceat lux vestra", let your light shine.
                  Align(
                    alignment: const Alignment(0, -0.22),
                    child: Opacity(
                      opacity: _bloom.value,
                      child: Transform.scale(
                        scale: .6 + .4 * _bloom.value,
                        child: Container(
                          width: bloom,
                          height: bloom,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppTheme.crimson.withValues(alpha: .20),
                                AppTheme.gold.withValues(alpha: .07),
                                Colors.transparent,
                              ],
                              stops: const [0, .45, 1],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Crest, name and motto
                  Align(
                    alignment: const Alignment(0, -0.12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Opacity(
                            opacity: _crest.value,
                            child: Transform.scale(
                              scale: .9 + .1 * _crest.value,
                              child: _crestTile(crest),
                            ),
                          ),
                          SizedBox(height: compact ? 22 : 30),
                          Opacity(
                            opacity: _name.value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - _name.value) * 12),
                              child: Column(
                                children: [
                                  Text(
                                    'Loyola College',
                                    textAlign: TextAlign.center,
                                    style: _serif.copyWith(
                                      color: AppTheme.white,
                                      fontSize: Responsive.sp(context, 32),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.4,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Chennai',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppTheme.white54,
                                      fontSize: Responsive.sp(context, 14),
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: .6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: compact ? 18 : 26),
                          Opacity(
                            opacity: _motto.value,
                            child: Column(
                              children: [
                                Text(
                                  'Luceat lux vestra',
                                  textAlign: TextAlign.center,
                                  style: _serif.copyWith(
                                    color: AppTheme.crimson.withValues(
                                      alpha: .92,
                                    ),
                                    fontSize: Responsive.sp(context, 16),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Let your light shine',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.white38,
                                    fontSize: Responsive.sp(context, 11.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Footer: honest status, thin progress line
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 36),
                        child: Opacity(
                          opacity: _motto.value,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 56,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: const LinearProgressIndicator(
                                    minHeight: 2,
                                    backgroundColor: Color(0x1FFFFFFF),
                                    color: AppTheme.crimson,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Signing you in',
                                style: TextStyle(
                                  color: AppTheme.white38,
                                  fontSize: 12,
                                  letterSpacing: .2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Crest on a soft disc with the same top-lit hairline used by the cards
  /// and the navigation dock.
  Widget _crestTile(double size) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: .30),
            Colors.white.withValues(alpha: .06),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.backgroundSoft,
        ),
        padding: EdgeInsets.all(size * .16),
        child: Image.asset(
          'assets/images/loyola_logo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.school_rounded,
            size: size * .42,
            color: AppTheme.white,
          ),
        ),
      ),
    );
  }
}
