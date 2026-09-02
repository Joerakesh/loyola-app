import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  AuthService(this._apiClient, this._storage);

  final ApiClient _apiClient;
  final SecureStorage _storage;

  Future<void> login({
    required String registrationNumber,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.login,
        data: {'registrationNumber': registrationNumber, 'password': password},
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

      await _storage.saveCredentials(
        registrationNumber: registrationNumber,
        password: password,
      );

      final expiresAt = authentication['expiresAt'];

      if (expiresAt != null) {
        await _storage.saveExpiresAt(expiresAt);
      }
    } on DioException catch (error) {
      debugPrint('HTTP STATUS: ${error.response?.statusCode}');
      debugPrint('HTTP RESPONSE: ${error.response?.data}');
      debugPrint('DIO ERROR: $error');

      final responseData = error.response?.data;

      if (responseData is Map && responseData['message'] != null) {
        throw Exception(responseData['message']);
      }

      throw Exception('Unable to connect to the Loyola ERP server');
    }
  }

  Future<void> refresh() async {
    final registrationNumber = await _storage.getRegistrationNumber();

    final password = await _storage.getPassword();

    if (registrationNumber == null || password == null) {
      throw Exception('No saved credentials');
    }

    final response = await _apiClient.dio.post(
      ApiConstants.refresh,
      data: {'registrationNumber': registrationNumber, 'password': password},
    );

    final data = response.data;

    if (data['status'] != 'success') {
      throw Exception(data['message'] ?? 'Refresh failed');
    }

    final authentication = data['authentication'];

    final token = authentication['token'];

    if (token == null) {
      throw Exception('Token missing from refresh response');
    }

    await _storage.saveToken(token);

    final expiresAt = authentication['expiresAt'];

    if (expiresAt != null) {
      await _storage.saveExpiresAt(expiresAt);
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post(ApiConstants.logout);
    } on DioException {
      // Even if the server request fails,
      // clear local authentication.
    } finally {
      await _storage.clear();
    }
  }
}
