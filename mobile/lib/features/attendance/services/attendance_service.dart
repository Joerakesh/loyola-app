import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  AttendanceService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<AttendanceRecord>> getHourlyAttendance() async {
    final response = await _apiClient.dio.get(
      '/attendance/hourly',
    );

    final data = response.data;

    if (data['status'] != 'success') {
      throw Exception(
        data['message'] ?? 'Unable to load attendance',
      );
    }

    final records = data['data'] as List<dynamic>? ?? [];

    return records
        .map(
          (item) => AttendanceRecord.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}
