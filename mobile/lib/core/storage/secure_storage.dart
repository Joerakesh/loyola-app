import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  // Keeps the active session token alive in memory. When "remember me" is
  // turned off the token is never written to persistent secure storage, so
  // the session only lasts for the current app run.
  String? _sessionToken;

  static const String tokenKey = 'auth_token';
  static const String registrationNumberKey = 'registration_number';
  static const String passwordKey = 'password';
  static const String expiresAtKey = 'expires_at';
  static const String rememberMeKey = 'remember_me';

  /// Saves the token for the current session. When [persist] is true the token
  /// is also stored permanently so it survives an app restart (remember me).
  Future<void> saveToken(String token, {bool persist = true}) async {
    _sessionToken = token;

    if (persist) {
      await _storage.write(key: tokenKey, value: token);
    } else {
      await _storage.delete(key: tokenKey);
    }
  }

  Future<String?> getToken() async {
    if (_sessionToken != null) {
      return _sessionToken;
    }

    return _storage.read(key: tokenKey);
  }

  Future<void> saveCredentials({
    required String registrationNumber,
    required String password,
  }) async {
    await _storage.write(key: registrationNumberKey, value: registrationNumber);

    await _storage.write(key: passwordKey, value: password);
  }

  Future<String?> getRegistrationNumber() async {
    return _storage.read(key: registrationNumberKey);
  }

  Future<String?> getPassword() async {
    return _storage.read(key: passwordKey);
  }

  Future<void> saveExpiresAt(int expiresAt) async {
    await _storage.write(key: expiresAtKey, value: expiresAt.toString());
  }

  Future<int?> getExpiresAt() async {
    final value = await _storage.read(key: expiresAtKey);

    if (value == null) {
      return null;
    }

    return int.tryParse(value);
  }

  Future<void> saveRememberMe(bool value) async {
    await _storage.write(key: rememberMeKey, value: value.toString());
  }

  Future<bool> getRememberMe() async {
    final value = await _storage.read(key: rememberMeKey);

    if (value == null) {
      return false;
    }

    return value == 'true';
  }

  /// Removes all saved credentials but keeps the in-memory session token.
  Future<void> clearCredentials() async {
    await _storage.delete(key: tokenKey);
    await _storage.delete(key: registrationNumberKey);
    await _storage.delete(key: passwordKey);
    await _storage.delete(key: expiresAtKey);
    await _storage.delete(key: rememberMeKey);
  }

  Future<void> clear() async {
    _sessionToken = null;
    await _storage.deleteAll();
  }
}