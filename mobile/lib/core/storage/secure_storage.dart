import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/auth_user.dart';

class SecureStorage {
  SecureStorage() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  // Keeps the active session token alive in memory so it survives for the
  // current run even if persistent storage clears it.
  String? _sessionToken;

  static const String tokenKey = 'auth_token';
  static const String expiresAtKey = 'expires_at';
  static const String userKey = 'auth_user';

  /// Saves the token for the current session and persists it so the login can
  /// be restored automatically on the next launch.
  Future<void> saveToken(String token) async {
    _sessionToken = token;
    await _storage.write(key: tokenKey, value: token);
  }

  Future<String?> getToken() async {
    if (_sessionToken != null) {
      return _sessionToken;
    }

    return _storage.read(key: tokenKey);
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

  Future<void> saveUser(AuthUser user) async {
    await _storage.write(
      key: userKey,
      value: jsonEncode({
        'id': user.id,
        'googleId': user.googleId,
        'email': user.email,
        'name': user.name,
        'avatarUrl': user.avatarUrl,
        'linkedEmails': user.linkedEmails,
        'erpLinked': user.erpLinked,
      }),
    );
  }

  Future<AuthUser?> getUser() async {
    final value = await _storage.read(key: userKey);

    if (value == null) {
      return null;
    }

    try {
      return AuthUser.fromJson(jsonDecode(value) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    _sessionToken = null;
    await _storage.deleteAll();
  }
}