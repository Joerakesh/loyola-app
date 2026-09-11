import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/responsive.dart';
import '../services/auth_provider.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_container.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
  }

  Future<void> _loginWithGoogle() async {
    final provider = context.read<AuthProvider>();

    await provider.loginWithGoogle();

    if (!mounted) return;

    if (provider.isAuthenticated) {
      return;
    }

    if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthProvider>();
    final compact = Responsive.isCompact(context);
    final avatarSize = Responsive.dp(context, compact ? 56 : 72);

    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.dp(context, 24),
                vertical: 16,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: GlassContainer(
                  padding: EdgeInsets.all(Responsive.dp(context, 26)),
                  blur: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/loyola_logo.png',
                            width: avatarSize,
                            height: avatarSize,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              width: avatarSize,
                              height: avatarSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.white.withValues(alpha: 0.1),
                                border: Border.all(
                                  color:
                                      AppColors.white.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.dp(context, 20)),
                      Text(
                        'Loyola ERP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: Responsive.sp(context, 26),
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Student Portal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: Responsive.dp(context, 32)),
                      _buildGoogleButton(provider),
                      SizedBox(height: Responsive.dp(context, 20)),
                      const Text(
                        'Sign in with your Loyola Google account to\naccess attendance, marks and more.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white54,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(AuthProvider provider) {
    return SizedBox(
      height: Responsive.dp(context, 52),
      child: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.white,
              ),
            )
          : ElevatedButton.icon(
              onPressed: _loginWithGoogle,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.background,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const _GoogleIcon(),
              label: Text(
                'Continue with Google',
                style: TextStyle(
                  fontSize: Responsive.sp(context, 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.g_mobiledata_rounded,
      size: 28,
      color: Color(0xFF4285F4),
    );
  }
}