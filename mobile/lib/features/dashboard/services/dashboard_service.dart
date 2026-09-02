import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/dashboard_model.dart';

class DashboardService {
  DashboardService(this._apiClient);

  final ApiClient _apiClient;

  Future<DashboardModel> getDashboard() async {
    final response = await _apiClient.dio.get(
      ApiConstants.dashboard,
    );

    final data = response.data;

    if (data['status'] != 'success') {
      throw Exception(
        data['message'] ?? 'Unable to load dashboard',
      );
    }

    return DashboardModel.fromJson(
      data['data'] as Map<String, dynamic>,
    );
  }
}

