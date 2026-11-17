import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app/app_router.dart';
import '../core/theme/app_theme.dart';
import 'theme_selection_screen.dart';
import '../core/theme/responsive.dart';
import '../services/auth_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/glass_background.dart';
import '../widgets/ui_kit.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  // ---------------------------------------------------------------------------
  // ACTIONS (same behaviour as before)
  // ---------------------------------------------------------------------------
  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
  }) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.backgroundSoft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          body,
          style: const TextStyle(
            color: AppTheme.white70,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.red,
              foregroundColor: Colors.white,
            ),
            child: Text(action),
          ),
        ],
      ),
    );
    return yes == true;
  }

  Future<void> _unlinkErp(BuildContext context) async {
    final yes = await _confirm(
      context,
      title: 'Unlink ERP account?',
      body:
          'Attendance, marks and other academic data will stop loading until you connect your ERP credentials again.',
      action: 'Unlink',
    );
    if (!yes || !context.mounted) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.unbindErp();
    if (!context.mounted) return;
    if (ok) {
      context.go(AppRoutes.erpSetup);
    } else {
      _snack(context, auth.error ?? 'Unable to unlink ERP');
    }
  }

  Future<void> _revokeGoogle(BuildContext context) async {
    final yes = await _confirm(
      context,
      title: 'Revoke Google sign-in?',
      body:
          'This removes Google sign-in from this account and signs you out. You can still get back in with your ERP credentials. Signing in with a different Google account creates a separate app account.',
      action: 'Revoke',
    );
    if (!yes || !context.mounted) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.unbindGoogle();
    if (!context.mounted) return;
    if (ok) {
      context.go(AppRoutes.login);
    } else {
      _snack(context, auth.error ?? 'Unable to revoke Google sign-in');
    }
  }

  Future<void> _changeGoogle(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    context.go(AppRoutes.login);
  }

  Future<void> _signOut(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (context.mounted) context.go(AppRoutes.login);
  }

  Future<bool?> _openSheet(BuildContext context, Widget sheet) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.backgroundSoft,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => sheet,
    );
  }

  Future<void> _updatePassword(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final done = await _openSheet(
      context,
      _CredentialSheet(
        title: 'Update ERP password',
        description:
            'Enter the new password you set on the Loyola ERP. It is verified with ERP before it is saved.',
        action: 'Verify and update',
        showRegistration: false,
        onSubmit: (reg, pass) async {
          final ok = await auth.updateErpPassword(pass);
          return ok ? null : (auth.error ?? 'Unable to update password');
        },
      ),
    );
    if (done == true && context.mounted) {
      _snack(context, 'ERP password updated and verified');
    }
  }

  Future<void> _changeErp(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final done = await _openSheet(
      context,
      _CredentialSheet(
        title: 'Switch ERP account',
        description:
            'Replace the linked registration number and password. The new account is verified before it replaces the old one.',
        action: 'Verify and switch',
        showRegistration: true,
        onSubmit: (reg, pass) async {
          final ok = await auth.bindErp(
            registrationNumber: reg,
            password: pass,
          );
          return ok ? null : (auth.error ?? 'Unable to update ERP');
        },
      ),
    );
    if (done == true && context.mounted) {
      _snack(context, 'ERP account updated');
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final googlePhotoUrl = user?.avatarUrl?.trim();
    final erp = user?.erpLinked == true;
    final googleLinked = user?.googleId.isNotEmpty == true;
    final email = user?.email.isNotEmpty == true ? user!.email : '';
    final side = Responsive.dp(context, 20);

    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(side, 10, side, 40),
                children: [
                  _header(context),
                  const SizedBox(height: 22),
                  _heading('Personalization'),
                  AppListGroup(
                    children: [
                      AppListTile(
                        icon: Icons.palette_outlined,
                        title: 'Themes',
                        subtitle: 'Choose a colour style for your Loyola app',
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ThemeSelectionScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _identityCard(email, googleLinked, erp, googlePhotoUrl),
                  if (auth.error != null) ...[
                    const SizedBox(height: 14),
                    AppCard(
                      rail: AppTheme.red,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppTheme.red,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              auth.error!,
                              style: const TextStyle(
                                color: AppTheme.white70,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  _heading('Google sign-in'),
                  AppListGroup(
                    children: [
                      AppListTile(
                        icon: Icons.account_circle_outlined,
                        title: email.isNotEmpty ? email : 'Google account',
                        subtitle: 'Used to sign in to this app',
                        trailing: StatusChip(
                          label: googleLinked ? 'Connected' : 'Not connected',
                          color: googleLinked
                              ? AppTheme.green
                              : AppTheme.white54,
                        ),
                      ),
                      AppListTile(
                        icon: Icons.swap_horiz_rounded,
                        title: 'Switch Google account',
                        subtitle: 'Sign out, then sign in with another account',
                        onTap: () => _changeGoogle(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _heading('Loyola ERP'),
                  AppListGroup(
                    children: [
                      AppListTile(
                        icon: Icons.school_outlined,
                        title: 'ERP connection',
                        subtitle: erp
                            ? 'Attendance, marks and subjects are syncing'
                            : 'Needed for attendance, marks and account recovery',
                        trailing: StatusChip(
                          label: erp ? 'Connected' : 'Not connected',
                          color: erp ? AppTheme.green : AppTheme.orange,
                        ),
                      ),
                      if (erp) ...[
                        AppListTile(
                          icon: Icons.lock_reset_rounded,
                          title: 'Update password',
                          subtitle: 'Changed it on the ERP? Update it here',
                          onTap: auth.isLoading
                              ? null
                              : () => _updatePassword(context),
                        ),
                        AppListTile(
                          icon: Icons.manage_accounts_outlined,
                          title: 'Switch ERP account',
                          subtitle: 'Use a different registration number',
                          onTap: auth.isLoading
                              ? null
                              : () => _changeErp(context),
                        ),
                      ] else
                        AppListTile(
                          icon: Icons.link_rounded,
                          title: 'Connect ERP account',
                          subtitle: 'Link your registration number',
                          onTap: () => context.go(AppRoutes.erpSetup),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _heading(
                    'Disconnect',
                    note: 'These change how you can sign in.',
                  ),
                  AppListGroup(
                    children: [
                      Opacity(
                        opacity: erp ? 1 : 0.45,
                        child: AppListTile(
                          icon: Icons.link_off_rounded,
                          iconColor: AppTheme.red,
                          title: 'Revoke Google sign-in',
                          subtitle: erp
                              ? 'Keep access with your ERP credentials'
                              : 'Connect ERP first to enable this',
                          onTap: (erp && !auth.isLoading)
                              ? () => _revokeGoogle(context)
                              : null,
                        ),
                      ),
                      if (erp)
                        AppListTile(
                          icon: Icons.power_settings_new_rounded,
                          iconColor: AppTheme.red,
                          title: 'Unlink ERP account',
                          subtitle: 'Stops academic data from loading',
                          onTap: auth.isLoading
                              ? null
                              : () => _unlinkErp(context),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _signOut(context),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text(
                        'Sign out',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.red,
                        side: BorderSide(
                          color: AppTheme.red.withValues(alpha: 0.7),
                        ),
                        backgroundColor: AppTheme.red.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppRadius.surface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (auth.isLoading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    color: AppTheme.crimson,
                    backgroundColor: Colors.transparent,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PIECES
  // ---------------------------------------------------------------------------
  Widget _header(BuildContext context) {
    return Row(
      children: [
        PressableScale(
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.backgroundSoft,
              border: Border.all(color: AppTheme.outline),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Account & security',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.white,
              fontSize: Responsive.sp(context, 24),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _identityCard(
    String email,
    bool googleLinked,
    bool erp,
    String? googlePhotoUrl,
  ) {
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'S';
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppTheme.crimson,
                backgroundImage:
                    googlePhotoUrl != null && googlePhotoUrl.isNotEmpty
                    ? NetworkImage(googlePhotoUrl)
                    : null,
                child: googlePhotoUrl == null || googlePhotoUrl.isEmpty
                    ? Text(
                        initial,
                        style: const TextStyle(
                          color: AppTheme.background,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email.isNotEmpty ? email : 'Your account',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      googleLinked
                          ? 'Signed in with Google'
                          : 'Signed in with ERP',
                      style: const TextStyle(
                        color: AppTheme.white54,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(
                label: googleLinked ? 'Google linked' : 'Google not linked',
                color: googleLinked ? AppTheme.green : AppTheme.white54,
                icon: googleLinked
                    ? Icons.check_circle_rounded
                    : Icons.remove_circle_outline_rounded,
              ),
              StatusChip(
                label: erp ? 'ERP linked' : 'ERP not linked',
                color: erp ? AppTheme.green : AppTheme.orange,
                icon: erp
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heading(String title, {String? note}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 3),
            Text(
              note,
              style: const TextStyle(color: AppTheme.white54, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// CREDENTIAL BOTTOM SHEET (password only, or registration number + password)
// =============================================================================
class _CredentialSheet extends StatefulWidget {
  const _CredentialSheet({
    required this.title,
    required this.description,
    required this.action,
    required this.showRegistration,
    required this.onSubmit,
  });

  final String title;
  final String description;
  final String action;
  final bool showRegistration;

  /// Returns null on success, or an error message to show inline.
  final Future<String?> Function(String registration, String password) onSubmit;

  @override
  State<_CredentialSheet> createState() => _CredentialSheetState();
}

class _CredentialSheetState extends State<_CredentialSheet> {
  final _form = GlobalKey<FormState>();
  final _reg = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _reg.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.onSubmit(_reg.text.trim(), _pass.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.inner),
      borderSide: BorderSide(color: c, width: w),
    );

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.white54, fontSize: 14),
      prefixIcon: Icon(icon, color: AppTheme.white54, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: border(Colors.white.withValues(alpha: 0.10)),
      enabledBorder: border(Colors.white.withValues(alpha: 0.10)),
      focusedBorder: border(AppTheme.crimson, 1.4),
      errorBorder: border(AppTheme.red),
      focusedErrorBorder: border(AppTheme.red, 1.4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        4,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                color: AppTheme.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.description,
              style: const TextStyle(
                color: AppTheme.white54,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            if (widget.showRegistration) ...[
              TextFormField(
                controller: _reg,
                enabled: !_busy,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: AppTheme.white, fontSize: 15),
                decoration: _decoration(
                  'Registration number',
                  Icons.badge_outlined,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _pass,
              enabled: !_busy,
              obscureText: _hide,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              style: const TextStyle(color: AppTheme.white, fontSize: 15),
              decoration: _decoration(
                widget.showRegistration ? 'ERP password' : 'New ERP password',
                Icons.lock_outline_rounded,
                suffix: IconButton(
                  onPressed: () => setState(() => _hide = !_hide),
                  icon: Icon(
                    _hide
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppTheme.white54,
                    size: 20,
                  ),
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppTheme.red,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppTheme.red,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.background,
                        ),
                      )
                    : Text(widget.action),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
