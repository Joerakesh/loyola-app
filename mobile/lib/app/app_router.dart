import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_client.dart';
import '../screens/attendance_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/marks_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/shell/app_shell.dart';
import '../screens/splash_screen.dart';
import '../screens/subjects_screen.dart';
import '../services/attendance_service.dart';
import '../services/auth_provider.dart';
import '../services/cache_warmup.dart';
import '../services/dashboard_service.dart';
import '../services/marks_service.dart';
import '../services/profile_service.dart';
import '../services/subject_service.dart';

class AppRouter {
  AppRouter({required this.apiClient, required this.authProvider}) {
    dashboardService = DashboardService(apiClient);
    attendanceService = AttendanceService(apiClient);
    marksService = MarksService(apiClient);
    subjectService = SubjectService(apiClient);
    profileService = ProfileService(apiClient);
    warmup = CacheWarmup(
      dashboardService: dashboardService,
      attendanceService: attendanceService,
      marksService: marksService,
      subjectService: subjectService,
      profileService: profileService,
    );
  }

  final ApiClient apiClient;
  final AuthProvider authProvider;

  late final DashboardService dashboardService;
  late final AttendanceService attendanceService;
  late final MarksService marksService;
  late final SubjectService subjectService;
  late final ProfileService profileService;

  late final CacheWarmup warmup;

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: _redirect,
    errorBuilder: (context, state) =>
        _NotFoundScreen(location: state.uri.toString()),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) =>
            SplashScreen(authProvider: authProvider, warmup: warmup),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      // AppShell containing the 5 main navigation tabs
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => DashboardScreen(
                  dashboardService: dashboardService,
                  attendanceService: attendanceService,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.attendance,
                builder: (context, state) =>
                    AttendanceScreen(attendanceService: attendanceService),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.subjects,
                builder: (context, state) =>
                    SubjectsScreen(subjectService: subjectService),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.marks,
                builder: (context, state) =>
                    MarksScreen(marksService: marksService),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) =>
                    ProfileScreen(profileService: profileService),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;
    final isLoggedIn = authProvider.isAuthenticated;

    if (location == AppRoutes.splash) return null;

    if (location == AppRoutes.login) {
      return isLoggedIn ? AppRoutes.home : null;
    }

    if (!isLoggedIn) return AppRoutes.login;

    return null;
  }

  void refresh() => router.refresh();
}

class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/home';
  static const String attendance = '/attendance';
  static const String subjects = '/subjects';
  static const String marks = '/marks';
  static const String profile = '/profile';
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen({required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.signpost_outlined,
              size: 48,
              color: Colors.white38,
            ),
            const SizedBox(height: 12),
            const Text('Route not found'),
            const SizedBox(height: 4),
            Text(location),
          ],
        ),
      ),
    );
  }
}
