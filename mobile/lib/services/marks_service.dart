import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/cache/data_cache.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/marks_model.dart';

class MarksService {
  MarksService(this._apiClient, {DataCache? cache})
      : _cache = cache ?? DataCache.instance;

  final ApiClient _apiClient;
  final DataCache _cache;

  Future<List<CourseMarks>?> getCachedMarks() async {
    final data = await _cache.load(CacheKeys.marks);
    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (item) => CourseMarks.fromJson(item.cast<String, dynamic>()),
          )
          .toList();
    }
    return null;
  }

  Future<FetchResult<List<CourseMarks>>> fetchMarks() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.marks);
      final data = response.data;

      if (data is! Map<String, dynamic> || data['status'] != 'success') {
        throw Exception(
          (data is Map && data['message']?.toString().isNotEmpty == true)
              ? data['message'].toString()
              : 'Unable to load marks',
        );
      }

      final payload = data['data'] as List<dynamic>? ?? [];

      final records = payload
          .whereType<Map>()
          .map((item) => CourseMarks.fromJson(item.cast<String, dynamic>()))
          .toList();

      final changed = await _cache.isChanged(CacheKeys.marks, payload);
      await _cache.save(CacheKeys.marks, payload);

      return FetchResult(data: records, changed: changed);
    } on DioException catch (error) {
      debugPrint('HTTP STATUS: ${error.response?.statusCode}');
      debugPrint('HTTP RESPONSE: ${error.response?.data}');
      debugPrint('DIO ERROR: $error');

      final responseData = error.response?.data;

      if (responseData is Map && responseData['message'] != null) {
        throw Exception(responseData['message']);
      }

      throw Exception(
        'Unable to connect to the Loyola ERP server to fetch marks',
      );
    }
  }
}