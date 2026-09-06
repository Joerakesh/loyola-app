import 'package:flutter/foundation.dart';

import '../core/cache/data_cache.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService);

  final AuthService _authService;

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;

  /// Attempts to restore the previous session automatically. Returns true
  /// when the user is in, false when the splash screen should send them to
  /// the login screen.
  Future<bool> autoLogin() async {
    final remembered = await _authService.hasRememberMe();

    if (!remembered) {
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }

    if (await _authService.hasValidSession()) {
      _isAuthenticated = true;
      _error = null;
      notifyListeners();
      return true;
    }

    // Token expired or missing: renew it using the saved credentials.
    await refresh();

    return _isAuthenticated;
  }

  Future<void> login({
    required String registrationNumber,
    required String password,
    required bool rememberMe,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.login(
        registrationNumber: registrationNumber,
        password: password,
        rememberMe: rememberMe,
      );

      _isAuthenticated = true;
    } catch (error) {
      debugPrint('LOGIN ERROR: $error');
      _error = error.toString();
      _isAuthenticated = false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    try {
      await _authService.refresh();
      _isAuthenticated = true;
      _error = null;
    } catch (error) {
      _isAuthenticated = false;
      _error = 'Session expired';
    }

    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();

    // Clear cached payloads so the next user never sees this session's data.
    await DataCache.instance.clearAll();

    _isAuthenticated = false;

    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}