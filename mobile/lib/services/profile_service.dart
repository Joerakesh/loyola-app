import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/cache/data_cache.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/profile_model.dart';

class ProfileService {
  ProfileService(this._apiClient, {DataCache? cache})
      : _cache = cache ?? DataCache.instance;

  final ApiClient _apiClient;
  final DataCache _cache;

  Future<StudentProfile?> getCachedProfile() async {
    final data = await _cache.load(CacheKeys.profile);
    if (data is Map) {
      return StudentProfile.fromJson(data.cast<String, dynamic>());
    }
    return null;
  }

  Future<FetchResult<StudentProfile>> fetchProfile() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.profile);
      final data = response.data;

      if (data is! Map<String, dynamic> || data['status'] != 'success') {
        throw Exception(
          (data is Map && data['message']?.toString().isNotEmpty == true)
              ? data['message'].toString()
              : 'Unable to load profile',
        );
      }

      final payload = data['data'] as Map<String, dynamic>? ??
          <String, dynamic>{};

      final changed = await _cache.isChanged(CacheKeys.profile, payload);
      await _cache.save(CacheKeys.profile, payload);

      return FetchResult(
        data: StudentProfile.fromJson(payload),
        changed: changed,
      );
    } on DioException catch (error) {
      debugPrint('HTTP STATUS: ${error.response?.statusCode}');
      debugPrint('HTTP RESPONSE: ${error.response?.data}');
      debugPrint('DIO ERROR: $error');

      final responseData = error.response?.data;

      if (responseData is Map && responseData['message'] != null) {
        throw Exception(responseData['message']);
      }

      throw Exception(
        'Unable to connect to the Loyola ERP server to fetch your profile',
      );
    }
  }
}