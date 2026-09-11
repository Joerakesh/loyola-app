import '../core/cache/data_cache.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/dashboard_model.dart';

class DashboardService {
  DashboardService(this._apiClient, {DataCache? cache})
      : _cache = cache ?? DataCache.instance;

  final ApiClient _apiClient;
  final DataCache _cache;

  Future<DashboardModel?> getCachedDashboard() async {
    final data = await _cache.load(CacheKeys.dashboard);
    if (data is Map<String, dynamic>) {
      return DashboardModel.fromJson(data);
    }
    return null;
  }

  Future<FetchResult<DashboardModel>> fetchDashboard() async {
    final response = await _apiClient.dio.get(
      ApiConstants.dashboard,
    );

    final data = response.data;

    if (data is! Map<String, dynamic> || data['status'] != 'success') {
      throw Exception(
        (data is Map && data['message']?.toString().isNotEmpty == true)
            ? data['message'].toString()
            : 'Unable to load dashboard',
      );
    }

    final payload = data['data'] as Map<String, dynamic>? ??
        <String, dynamic>{};

    final changed = await _cache.isChanged(CacheKeys.dashboard, payload);
    await _cache.save(CacheKeys.dashboard, payload);

    return FetchResult(
      data: DashboardModel.fromJson(payload),
      changed: changed,
    );
  }
}