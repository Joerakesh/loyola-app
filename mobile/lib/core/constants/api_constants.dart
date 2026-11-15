import 'package:flutter/foundation.dart';
class ApiConstants {
  ApiConstants._();
  static const String _envBaseUrl=String.fromEnvironment('API_BASE_URL');
  static const String _defaultLocal='https://loyola-app-livid.vercel.app/api/v1';
  static const String _host='https://loyola-app-livid.vercel.app/api/v1';
  static String get baseUrl=>_envBaseUrl.isNotEmpty?_envBaseUrl:(kIsWeb?_host:_defaultLocal);
  static const String googleLogin='/auth/google', erpLogin='/auth/erp', refresh='/auth/refresh', logout='/auth/logout', me='/auth/google/me';
  static const String bindErp='/auth/bind-erp', erpPassword='/auth/erp-password', unbindErp='/auth/unbind-erp', unbindGoogle='/auth/unbind-google';
  static const String dashboard='/dashboard', marks='/marks/internal', subjects='/subjects', profile='/student/profile', studentPhoto='/student/photo';
  static const String attendanceHourly='/attendance/hourly', attendanceSummary='/attendance/summary', collegeUpdates='/college/updates', collegeCalendar='/college/calendar';
}
