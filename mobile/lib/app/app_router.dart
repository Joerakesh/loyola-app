import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/network/api_client.dart';
import '../screens/attendance_screen.dart';
import '../screens/academics_hub_screen.dart';
import '../screens/campus_hub_screen.dart';
import '../screens/academic_calendar_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/college_updates_screen.dart';
import '../screens/erp_setup_screen.dart';
import '../screens/account_settings_screen.dart';
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
import '../services/college_updates_service.dart';
import '../services/marks_service.dart';
import '../services/profile_service.dart';
import '../services/subject_service.dart';

class AppRouter {
  AppRouter({required this.apiClient, required this.authProvider}) {
    dashboardService = DashboardService(apiClient);
    collegeUpdatesService = CollegeUpdatesService(apiClient);
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
  late final CollegeUpdatesService collegeUpdatesService;
  late final AttendanceService attendanceService;
  late final MarksService marksService;
  late final SubjectService subjectService;
  late final ProfileService profileService;
  late final CacheWarmup warmup;
  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: _redirect,
    errorBuilder: (c, s) => _NotFoundScreen(location: s.uri.toString()),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (c, s) =>
            SplashScreen(authProvider: authProvider, warmup: warmup),
      ),
      GoRoute(path: AppRoutes.login, builder: (c, s) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.erpSetup,
        builder: (c, s) => const ErpSetupScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (c, s, n) => AppShell(navigationShell: n),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (c, s) => DashboardScreen(
                  dashboardService: dashboardService,
                  attendanceService: attendanceService,
                  collegeUpdatesService: collegeUpdatesService,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.academics,
                builder: (c, s) => AcademicsHubScreen(
                  attendanceService: attendanceService,
                  subjectService: subjectService,
                  marksService: marksService,
                ),
                routes: [
                  GoRoute(
                    path: 'attendance',
                    builder: (c, s) =>
                        AttendanceScreen(attendanceService: attendanceService),
                  ),
                  GoRoute(
                    path: 'subjects',
                    builder: (c, s) =>
                        SubjectsScreen(subjectService: subjectService),
                  ),
                  GoRoute(
                    path: 'marks',
                    builder: (c, s) => MarksScreen(marksService: marksService),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.campus,
                builder: (c, s) =>
                    CampusHubScreen(service: collegeUpdatesService),
                routes: [
                  GoRoute(
                    path: 'updates',
                    builder: (c, s) =>
                        CollegeUpdatesScreen(service: collegeUpdatesService),
                  ),
                  GoRoute(
                    path: 'calendar',
                    builder: (c, s) =>
                        AcademicCalendarScreen(service: collegeUpdatesService),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (c, s) =>
                    ProfileScreen(profileService: profileService),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (c, s) => const AccountSettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  String? _redirect(BuildContext context, GoRouterState state) {
    final loc = state.matchedLocation;
    final logged = authProvider.isAuthenticated;
    if (loc == AppRoutes.splash) return null;
    if (!logged) return loc == AppRoutes.login ? null : AppRoutes.login;
    if (authProvider.requiresErpSetup)
      return loc == AppRoutes.erpSetup ? null : AppRoutes.erpSetup;
    if (loc == AppRoutes.login || loc == AppRoutes.erpSetup)
      return AppRoutes.home;
    return null;
  }

  void refresh() => router.refresh();
}

class AppRoutes {
  AppRoutes._();
  static const splash = '/splash',
      login = '/login',
      erpSetup = '/setup/erp',
      settings = '/settings',
      home = '/home',
      academics = '/academics',
      attendance = '/academics/attendance',
      subjects = '/academics/subjects',
      marks = '/academics/marks',
      campus = '/campus',
      profile = '/profile',
      updates = '/campus/updates',
      calendar = '/campus/calendar';
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen({required this.location});
  final String location;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.signpost_outlined, size: 48, color: Colors.white38),
          const SizedBox(height: 12),
          const Text('Route not found'),
          const SizedBox(height: 4),
          Text(location),
        ],
      ),
    ),
  );
}
