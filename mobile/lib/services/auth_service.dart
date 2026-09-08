import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../models/auth_user.dart';

class AuthService {
  AuthService(this._apiClient, this._storage);

  final ApiClient _apiClient;
  final SecureStorage _storage;

  /// Exchanges a Firebase Google ID token for a backend session (JWT).
  Future<AuthUser> loginWithGoogle({required String idToken}) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.googleLogin,
        data: {'idToken': idToken},
      );

      final data = response.data;

      if (data['status'] != 'success') {
        throw Exception(data['message'] ?? 'Login failed');
      }

      final authentication = data['authentication'];

      if (authentication == null) {
        throw Exception('Authentication data missing');
      }

      final token = authentication['token'];

      if (token == null) {
        throw Exception('Token missing from response');
      }

      await _storage.saveToken(token);

      final expiresAt = authentication['expiresAt'];

      if (expiresAt != null) {
        await _storage.saveExpiresAt(expiresAt);
      }

      final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
      await _storage.saveUser(user);

      return user;
    } on DioException catch (error) {
      debugPrint('HTTP STATUS: ${error.response?.statusCode}');
      debugPrint('HTTP RESPONSE: ${error.response?.data}');
      debugPrint('DIO ERROR: $error');

      final responseData = error.response?.data;

      if (responseData is Map && responseData['message'] != null) {
        throw Exception(responseData['message']);
      }

      throw Exception('Unable to connect to Loyola servers');
    }
  }

  /// Re-issues the session JWT using the existing (still valid) token.
  Future<AuthUser?> refresh() async {
    final token = await _storage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No session to refresh');
    }

    final response = await _apiClient.dio.post(ApiConstants.refresh);

    final data = response.data;

    if (data['status'] != 'success') {
      throw Exception(data['message'] ?? 'Refresh failed');
    }

    final authentication = data['authentication'];
    final newToken = authentication['token'];

    if (newToken == null) {
      throw Exception('Token missing from refresh response');
    }

    await _storage.saveToken(newToken);

    final expiresAt = authentication['expiresAt'];

    if (expiresAt != null) {
      await _storage.saveExpiresAt(expiresAt);
    }

    final storedUser = await _storage.getUser();
    return storedUser;
  }

  Future<AuthUser?> getUser() => _storage.getUser();

  Future<bool> hasValidSession() async {
    final token = await _storage.getToken();
    final expiresAt = await _storage.getExpiresAt();

    if (token == null || token.isEmpty) {
      return false;
    }

    if (expiresAt != null &&
        expiresAt < DateTime.now().millisecondsSinceEpoch) {
      return false;
    }

    return true;
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post(ApiConstants.logout);
    } on DioException {
      // Even if the server request fails, clear local state.
    } finally {
      await _storage.clear();
    }
  }
}