import 'package:flutter/material.dart';
import 'package:loyola_erp/features/attendance/presentation/attendance_screen.dart';

import '../core/network/api_client.dart';
import '../features/attendance/services/attendance_service.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/dashboard/services/dashboard_service.dart';
import '../features/marks/presentation/marks_screen.dart';
import '../features/marks/services/marks_service.dart';

class AppRouter {
  AppRouter(this.apiClient) {
    // Initialize services once
    dashboardService = DashboardService(apiClient);
    attendanceService = AttendanceService(apiClient);
    marksService = MarksService(apiClient);
  }

  final ApiClient apiClient;

  late final DashboardService dashboardService;
  late final AttendanceService attendanceService;
  late final MarksService marksService;

  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String marks = '/marks';
  static const String attendance = '/attendance';

  Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case dashboard:
        return MaterialPageRoute(
          builder: (_) => DashboardScreen(
            dashboardService: dashboardService,
            attendanceService: attendanceService,
          ),
        );

      case marks:
        return MaterialPageRoute(
          builder: (_) => MarksScreen(marksService: marksService),
        );
      // Inside generateRoute switch:
      case attendance:
        return MaterialPageRoute(
          builder: (_) =>
              AttendanceScreen(attendanceService: attendanceService),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
