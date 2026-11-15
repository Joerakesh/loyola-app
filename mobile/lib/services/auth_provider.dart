import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/cache/data_cache.dart';
import '../models/auth_user.dart';
import 'auth_service.dart';
import 'google_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService, this._googleAuthService);

  final AuthService _authService;
  final GoogleAuthService _googleAuthService;

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;
  AuthUser? _user;
  String? _studentPhotoDataUri;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  AuthUser? get user => _user;
  String? get studentPhotoDataUri => _studentPhotoDataUri;

  /// Prefer the ERP photo, but always fall back to the Google account photo.
  String? get profileAvatarUrl {
    final erpPhoto = _studentPhotoDataUri;
    if (erpPhoto != null && erpPhoto.startsWith('data:image/')) {
      return erpPhoto;
    }

    final googlePhoto = _user?.avatarUrl?.trim();
    return googlePhoto == null || googlePhoto.isEmpty ? null : googlePhoto;
  }

  /// Allows screens to retry the ERP photo fetch when the user opens Profile.
  Future<void> refreshStudentPhoto() async {
    if (_user?.erpLinked != true) return;
    await _refreshStudentPhoto();
  }

  /// Restores the account from the backend using the locally stored JWT.
  Future<bool> autoLogin() async {
    try {
      if (!await _authService.hasValidSession()) {
        await _clearFailedSession();
        return false;
      }

      _user = await _authService.getCurrentUser();
      _isAuthenticated = true;
      await _loadCachedStudentPhoto();
      if (_user?.erpLinked == true) unawaited(_refreshStudentPhoto());
      _error = null;
      notifyListeners();
      return true;
    } catch (error) {
      debugPrint('AUTO-LOGIN FAILED: $error');
      await _clearFailedSession();
      return false;
    }
  }

  Future<void> _clearFailedSession() async {
    await _authService.clearLocalSession();
    await DataCache.instance.clearAll();
    _user = null;
    _studentPhotoDataUri = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Signs in with Google (Firebase popup) and exchanges the ID token for a
  /// backend session.
  Future<void> loginWithGoogle() async {
    _setLoading(true);
    _error = null;

    try {
      final idToken = await _googleAuthService.signInWithGoogle();
      final user = await _authService.loginWithGoogle(idToken: idToken);

      _user = user;
      _isAuthenticated = true;
      await _loadCachedStudentPhoto();
      if (user.erpLinked) unawaited(_refreshStudentPhoto());
    } catch (error) {
      debugPrint('LOGIN ERROR: $error');
      _error = error.toString();
      _isAuthenticated = false;
    } finally {
      _setLoading(false);
    }
  }

  /// Signs in directly with the student's Loyola ERP credentials.
  Future<void> loginWithErp({
    required String username,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final user = await _authService.loginWithErp(
        username: username,
        password: password,
      );
      _user = user;
      _isAuthenticated = true;
      await _loadCachedStudentPhoto();
      if (user.erpLinked) unawaited(_refreshStudentPhoto());
    } catch (error) {
      debugPrint('ERP LOGIN ERROR: $error');
      _error = error.toString().replaceFirst('Exception: ', '');
      _isAuthenticated = false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    await _googleAuthService.signOut();

    // Clear cached payloads so the next user never sees this session's data.
    await DataCache.instance.clearAll();

    _user = null;
    _studentPhotoDataUri = null;
    _isAuthenticated = false;

    notifyListeners();
  }

  Future<void> _loadCachedStudentPhoto() async {
    final cached = await DataCache.instance.load(CacheKeys.studentPhoto);
    if (cached is String && cached.startsWith('data:image/')) {
      _studentPhotoDataUri = cached;
      notifyListeners();
    }
  }

  Future<void> _refreshStudentPhoto() async {
    try {
      final photo = await _authService.fetchStudentPhoto();
      if (photo == null || photo == _studentPhotoDataUri) return;

      await DataCache.instance.save(CacheKeys.studentPhoto, photo);
      _studentPhotoDataUri = photo;
      notifyListeners();
    } catch (error) {
      debugPrint('STUDENT PHOTO FETCH FAILED: $error');
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
