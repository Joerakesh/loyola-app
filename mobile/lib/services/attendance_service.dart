import '../core/cache/data_cache.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/attendance_model.dart';
import 'package:flutter/foundation.dart';

class AttendanceService {
  AttendanceService(this._apiClient, {DataCache? cache})
      : _cache = cache ?? DataCache.instance;

  final ApiClient _apiClient;
  final DataCache _cache;

  Future<List<AttendanceRecord>?> getCachedHourlyAttendance() async {
    final data = await _cache.load(CacheKeys.attendanceHourly);
    if (data is List) {
      return data
          .map((item) => AttendanceRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return null;
  }

  Future<dynamic> getCachedAttendanceSummary() async {
    return _cache.load(CacheKeys.attendanceSummary);
  }

  Future<FetchResult<List<AttendanceRecord>>> fetchHourlyAttendance() async {
    final response = await _apiClient.dio.get(ApiConstants.attendanceHourly);

    final data = response.data;

    if (data['status'] != 'success') {
      throw Exception(data['message'] ?? 'Unable to load attendance');
    }

    final payload = data['data'] as List<dynamic>? ?? [];

    final records = payload
        .map((item) => AttendanceRecord.fromJson(item as Map<String, dynamic>))
        .toList();

    final changed = await _cache.isChanged(
      CacheKeys.attendanceHourly,
      payload,
    );
    await _cache.save(CacheKeys.attendanceHourly, payload);

    return FetchResult(data: records, changed: changed);
  }

  Future<FetchResult<dynamic>> fetchAttendanceSummary() async {
    final response = await _apiClient.dio.get(ApiConstants.attendanceSummary);

    final data = response.data;
    debugPrint('========== ATTENDANCE SUMMARY API ==========');
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Response: ${response.data}');
    debugPrint('=============================================');
    if (data['status'] != 'success') {
      throw Exception(data['message'] ?? 'Unable to load attendance summary');
    }

    final payload = data['data'];

    final changed = await _cache.isChanged(CacheKeys.attendanceSummary, payload);
    await _cache.save(CacheKeys.attendanceSummary, payload);

    return FetchResult(data: payload, changed: changed);
  }
}