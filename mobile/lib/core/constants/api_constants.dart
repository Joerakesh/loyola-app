class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://loyola-app-livid.vercel.app/api/v1';
  // static const String baseUrl = 'http://localhost:5000/api/v1';

  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  static const String dashboard = '/dashboard';
  static const String marks = '/marks/internal';
  static const String subjects = '/subjects';
  static const String profile = '/student/profile';

  static const String attendanceHourly = '/attendance/hourly';
  static const String attendanceSummary = '/attendance/summary';
}