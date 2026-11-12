import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class CollegeUpdatesService {
  CollegeUpdatesService(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> fetchUpdates({bool refresh = false}) async {
    final response = await _apiClient.dio.get(
      ApiConstants.collegeUpdates,
      queryParameters: refresh ? {'refresh': 1} : null,
    );

    final payload = response.data;
    if (payload is! Map<String, dynamic> || payload['status'] != 'success') {
      throw Exception(
        payload is Map && payload['message'] != null
            ? payload['message'].toString()
            : 'Unable to load college updates',
      );
    }

    final data = payload['data'];
    if (data is! Map) {
      throw Exception('The college updates API returned an invalid response');
    }

    return data.cast<String, dynamic>();
  }
}
