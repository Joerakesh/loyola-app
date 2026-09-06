import '../core/cache/data_cache.dart';
import 'attendance_service.dart';
import 'dashboard_service.dart';
import 'marks_service.dart';
import 'profile_service.dart';
import 'subject_service.dart';

/// Prefetches every endpoint used by the app so that screens can render
/// instantly from the cached payloads the moment they are opened.
class CacheWarmup {
  CacheWarmup({
    required this.dashboardService,
    required this.attendanceService,
    required this.marksService,
    required this.subjectService,
    required this.profileService,
  });

  final DashboardService dashboardService;
  final AttendanceService attendanceService;
  final MarksService marksService;
  final SubjectService subjectService;
  final ProfileService profileService;

  /// Runs all the fetches in parallel as a best-effort operation. Individual
  /// failures are ignored so one bad endpoint does not block the app start.
  Future<void> prefetchAll() async {
    final tasks = <Future<void>>[
      _quiet(dashboardService.fetchDashboard),
      _quiet(attendanceService.fetchHourlyAttendance),
      _quiet(attendanceService.fetchAttendanceSummary),
      _quiet(marksService.fetchMarks),
      _quiet(subjectService.fetchSubjects),
      _quiet(profileService.fetchProfile),
    ];

    await Future.wait(tasks);
  }

  Future<void> _quiet(Future<FetchResult<dynamic>> Function() task) async {
    try {
      await task();
    } catch (_) {
      // Ignore: the screen will still show cached data and re-fetch later.
    }
  }
}