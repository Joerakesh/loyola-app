import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/marks_model.dart';

class MarksService {
  MarksService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<CourseMarks>> getMarks() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.marks);
      final data = response.data;

      if (data['status'] != 'success') {
        throw Exception(data['message'] ?? 'Unable to load marks');
      }

      final records = data['data'] as List<dynamic>? ?? [];

      return records
          .map((item) => CourseMarks.fromJson(item as Map<String, dynamic>))
          .toList();
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
