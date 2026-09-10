import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  /// Override at build time with
  /// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api/v1`.
  /// Android defaults to 127.0.0.1 with `adb reverse tcp:5000 tcp:5000`.
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  // static const String _defaultLocal = 'http://127.0.0.1:5000/api/v1';
  // static const String _host = 'http://127.0.0.1:5000/api/v1';
  static const String _defaultLocal =
      'https://loyola-app-livid.vercel.app/api/v1';
  static const String _host = 'https://loyola-app-livid.vercel.app/api/v1';

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    if (kIsWeb) {
      return _host;
    }
    return _defaultLocal;
  }

  static const String googleLogin = '/auth/google';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/google/me';

  static const String dashboard = '/dashboard';
  static const String marks = '/marks/internal';
  static const String subjects = '/subjects';
  static const String profile = '/student/profile';

  static const String attendanceHourly = '/attendance/hourly';
  static const String attendanceSummary = '/attendance/summary';
}
