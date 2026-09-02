import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String tokenKey = 'auth_token';
  static const String registrationNumberKey = 'registration_number';
  static const String passwordKey = 'password';
  static const String expiresAtKey = 'expires_at';

  Future<void> saveToken(String token) async {
    await _storage.write(key: tokenKey, value: token);
  }

  Future<String?> getToken() async {
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

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
