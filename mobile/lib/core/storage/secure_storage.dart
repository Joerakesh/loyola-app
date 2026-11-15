import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  // The backend JWT is the only authentication value persisted on-device.
  String? _sessionToken;

  static const String tokenKey = 'auth_token';

  Future<void> saveToken(String token) async {
    _sessionToken = token;
    await _storage.write(key: tokenKey, value: token);

    // Remove values saved by older app versions. User data is restored from
    // the backend using the JWT, and expiry is read from the JWT's exp claim.
    await _storage.delete(key: 'expires_at');
    await _storage.delete(key: 'auth_user');
  }

  Future<String?> getToken() async {
    if (_sessionToken != null) return _sessionToken;

    // One-time migration cleanup for existing installations.
    await _storage.delete(key: 'expires_at');
    await _storage.delete(key: 'auth_user');

    return _storage.read(key: tokenKey);
  }

  Future<void> clear() async {
    _sessionToken = null;
    await _storage.deleteAll();
  }
}
