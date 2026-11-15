import 'dart:convert';

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
      final token = authentication?['token'];
      if (token is! String || token.isEmpty) {
        throw Exception('Token missing from response');
      }

      await _storage.saveToken(token);
      return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
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

  /// Exchanges Loyola ERP credentials for a backend session (JWT).
  Future<AuthUser> loginWithErp({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.erpLogin,
        data: {'username': username.trim(), 'password': password},
      );
      final data = response.data;
      if (data['status'] != 'success') {
        throw Exception(data['message'] ?? 'ERP login failed');
      }

      final authentication = data['authentication'];
      final token = authentication?['token'];
      if (token is! String || token.isEmpty) {
        throw Exception('Authentication token missing from response');
      }

      await _storage.saveToken(token);
      return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData['message'] != null) {
        throw Exception(responseData['message']);
      }
      throw Exception('Unable to connect to Loyola servers');
    }
  }

  /// Restores the current account from the backend. The server resolves the
  /// user from the authenticated JWT, so no duplicate user snapshot is stored.
  Future<AuthUser> getCurrentUser() async {
    final response = await _apiClient.dio.get(ApiConstants.me);
    final data = response.data;

    if (data is! Map || data['status'] != 'success' || data['user'] is! Map) {
      throw Exception('Unable to restore account');
    }

    return AuthUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
  }

  /// Fetches the student's ERP photo using the authenticated backend session.
  Future<String?> fetchStudentPhoto() async {
    final response = await _apiClient.dio.get(ApiConstants.studentPhoto);
    final data = response.data;

    if (data is! Map || data['status'] != 'success') {
      throw Exception(
        data is Map
            ? data['message'] ?? 'Unable to fetch student photo'
            : 'Invalid student photo response',
      );
    }

    final payload = data['data'];
    final photo = payload is Map ? payload['photoDataUri'] : null;
    if (photo is! String || !photo.startsWith('data:image/')) {
      throw Exception('Student photo is missing from the ERP response');
    }

    return photo;
  }

  /// Checks the JWT's standard exp claim; no separate expiry value is needed.
  Future<bool> hasValidSession() async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) return false;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      if (payload is! Map || payload['exp'] is! num) return false;

      final expiresAtMs = (payload['exp'] as num).toInt() * 1000;
      return expiresAtMs > DateTime.now().millisecondsSinceEpoch;
    } catch (_) {
      return false;
    }
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

  /// Clears the local JWT after a failed session restoration.
  Future<void> clearLocalSession() => _storage.clear();
}
