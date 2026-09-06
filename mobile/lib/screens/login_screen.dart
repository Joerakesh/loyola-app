import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../services/auth_provider.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_container.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _registrationController = TextEditingController(text: '26-PDS-002');
  final _passwordController = TextEditingController(text: 'Joe@2006');
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
  }

  @override
  void dispose() {
    _registrationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<AuthProvider>();

    await provider.login(
      registrationNumber: _registrationController.text.trim(),
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;

    if (provider.isAuthenticated) {
      // The router redirect will move the user into the app automatically.
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

    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassContainer(
                padding: const EdgeInsets.all(28),
                blur: 20,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white.withValues(alpha: 0.1),
                            border: Border.all(
                              color: AppColors.white.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            size: 36,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Loyola ERP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Student Portal Login',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildGlassTextField(
                        controller: _registrationController,
                        labelText: 'Registration Number',
                        prefixIcon: Icons.badge_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your registration number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildGlassTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.white60,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            height: 44,
                            child: FittedBox(
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() => _rememberMe = value ?? false);
                                },
                                activeColor: AppColors.crimson,
                                checkColor: AppColors.white,
                                side: BorderSide(
                                  color: AppColors.white38,
                                  width: 1.6,
                                ),
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              'Remember me',
                              style: TextStyle(
                                color: AppColors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: provider.isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.background,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: provider.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.background,
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: AppColors.white, fontSize: 15),
      cursorColor: AppColors.white,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: AppColors.white60, fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: AppColors.white60, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.white.withValues(alpha: 0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.white, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.red, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF6961)),
      ),
      validator: validator,
    );
  }
}