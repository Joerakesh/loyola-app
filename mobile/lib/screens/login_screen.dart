import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/auth_provider.dart';

enum _LoginMethod { erp, google }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  _LoginMethod _method = _LoginMethod.erp;
  bool _obscurePassword = true;

  // CC0 image of Christ the King Church at Loyola College, Chennai.
  static const _campusImage =
      'https://commons.wikimedia.org/wiki/Special:FilePath/Chennai%2C_Loyola_College_church.JPG?width=1400';

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF7F8FA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithErp() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    await auth.loginWithErp(
      username: _usernameController.text,
      password: _passwordController.text,
    );
    if (!mounted || auth.isAuthenticated || auth.error == null) return;
    _showError(auth.error!);
  }

  Future<void> _loginWithGoogle() async {
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    await auth.loginWithGoogle();
    if (!mounted || auth.isAuthenticated || auth.error == null) return;
    _showError(auth.error!);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFB42318),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 330,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  _campusImage,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.2),
                  errorBuilder: (_, _, _) => const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF152C4A), Color(0xFF345B79)],
                      ),
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x55071120),
                        Color(0xAA071120),
                        Color(0xFFF7F8FA),
                      ],
                      stops: [0, 0.62, 1],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            padding: const EdgeInsets.all(5),
                            child: Image.asset(
                              'assets/images/loyola_logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.school_rounded,
                                color: Color(0xFF173451),
                              ),
                            ),
                          ),
                          const SizedBox(width: 11),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LOYOLA COLLEGE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  letterSpacing: 1.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'CHENNAI  ·  STUDENT PORTAL',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 184),
                      const Text(
                        'Your campus,\nall in one place.',
                        style: TextStyle(
                          color: Color(0xFF142B45),
                          fontSize: 31,
                          height: 1.08,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.1,
                        ),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'Sign in to stay connected with your academic life.',
                        style: TextStyle(
                          color: Color(0xFF657386),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 23),
                      Container(
                        padding: EdgeInsets.all(width < 380 ? 18 : 22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: const Color(0xFFE9EDF2)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x100E2844),
                              blurRadius: 28,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Welcome back',
                              style: TextStyle(
                                color: Color(0xFF142B45),
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Choose how you want to continue.',
                              style: TextStyle(
                                color: Color(0xFF7A8796),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F4F7),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Row(
                                children: [
                                  _methodTab(
                                    label: 'ERP credentials',
                                    selected: _method == _LoginMethod.erp,
                                    onTap: () => setState(
                                      () => _method = _LoginMethod.erp,
                                    ),
                                  ),
                                  _methodTab(
                                    label: 'Google',
                                    selected: _method == _LoginMethod.google,
                                    onTap: () => setState(
                                      () => _method = _LoginMethod.google,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_method == _LoginMethod.erp) ...[
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _fieldLabel('USERNAME / REGISTER NUMBER'),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _usernameController,
                                      keyboardType: TextInputType.text,
                                      textInputAction: TextInputAction.next,
                                      autocorrect: false,
                                      style: const TextStyle(
                                        color: Color(0xFF172B43),
                                        fontSize: 14,
                                      ),
                                      decoration: _inputDecoration(
                                        hint: 'Enter your ERP username',
                                        icon: Icons.person_outline_rounded,
                                      ),
                                      validator: (value) =>
                                          value == null || value.trim().isEmpty
                                              ? 'Enter your username or register number'
                                              : null,
                                    ),
                                    const SizedBox(height: 16),
                                    _fieldLabel('PASSWORD'),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _loginWithErp(),
                                      style: const TextStyle(
                                        color: Color(0xFF172B43),
                                        fontSize: 14,
                                      ),
                                      decoration: _inputDecoration(
                                        hint: 'Enter your ERP password',
                                        icon: Icons.lock_outline_rounded,
                                      ).copyWith(
                                        suffixIcon: IconButton(
                                          onPressed: () => setState(
                                            () => _obscurePassword = !_obscurePassword,
                                          ),
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: const Color(0xFF8793A1),
                                            size: 19,
                                          ),
                                        ),
                                      ),
                                      validator: (value) =>
                                          value == null || value.isEmpty
                                              ? 'Enter your password'
                                              : null,
                                    ),
                                    const SizedBox(height: 20),
                                    _primaryButton(
                                      label: 'Sign in to Loyola',
                                      loading: auth.isLoading,
                                      onPressed: _loginWithErp,
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              const Text(
                                'Use your Google account to securely sign in. '
                                'Continue with the account linked to your Loyola profile.',
                                style: TextStyle(
                                  color: Color(0xFF657386),
                                  fontSize: 13,
                                  height: 1.55,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 54,
                                child: OutlinedButton(
                                  onPressed: auth.isLoading ? null : _loginWithGoogle,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF172B43),
                                    side: const BorderSide(color: Color(0xFFDCE2E9)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          width: 21,
                                          height: 21,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF173451),
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _GoogleMark(),
                                            SizedBox(width: 11),
                                            Text(
                                              'Continue with Google',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            const Row(
                              children: [
                                Expanded(child: Divider(color: Color(0xFFE9EDF2))),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    'SECURE STUDENT ACCESS',
                                    style: TextStyle(
                                      color: Color(0xFFA0AAB6),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Color(0xFFE9EDF2))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Ad majorem Dei gloriam  ·  Let your light shine',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF8A96A4),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x100E2844),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? const Color(0xFF173451)
                  : const Color(0xFF8491A0),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: Color(0xFF536477),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFA3ADB9), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF8492A1), size: 19),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE5EAF0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE5EAF0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFF345B79), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFB42318)),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required bool loading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF173451),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF9AA8B5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w800,
        color: Color(0xFF4285F4),
        height: 1,
      ),
    );
  }
}
