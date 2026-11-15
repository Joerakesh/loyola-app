import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_router.dart';
import '../core/cache/data_cache.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/responsive.dart';
import '../models/attendance_model.dart';
import '../models/marks_model.dart';
import '../models/subject_model.dart';
import '../services/attendance_service.dart';
import '../services/marks_service.dart';
import '../services/subject_service.dart';
import '../widgets/glass_background.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';
import '../widgets/ui_kit.dart';

class AcademicsHubScreen extends StatefulWidget {
  const AcademicsHubScreen({
    super.key,
    required this.attendanceService,
    required this.subjectService,
    required this.marksService,
  });

  final AttendanceService attendanceService;
  final SubjectService subjectService;
  final MarksService marksService;

  @override
  State<AcademicsHubScreen> createState() => _AcademicsHubScreenState();
}

class _AcademicsHubScreenState extends State<AcademicsHubScreen> {
  List<AttendanceRecord> _attendance = [];
  List<Subject> _subjects = [];
  List<CourseMarks> _marks = [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCache();
    _refresh();
  }

  // ---------------------------------------------------------------------------
  // DATA (unchanged behaviour)
  // ---------------------------------------------------------------------------
  Future<void> _loadCache() async {
    try {
      final values = await Future.wait([
        widget.attendanceService.getCachedHourlyAttendance(),
        widget.subjectService.getCachedSubjects(),
        widget.marksService.getCachedMarks(),
      ]);
      if (!mounted) return;
      setState(() {
        _attendance = values[0] as List<AttendanceRecord>? ?? _attendance;
        _subjects = values[1] as List<Subject>? ?? _subjects;
        _marks = values[2] as List<CourseMarks>? ?? _marks;
        if (_attendance.isNotEmpty ||
            _subjects.isNotEmpty ||
            _marks.isNotEmpty) {
          _loading = false;
        }
      });
    } catch (_) {}
  }

  Future<void> _refresh() async {
    setState(() {
      _refreshing = true;
      _error = null;
    });
    final results = await Future.wait(
      [
        widget.attendanceService.fetchHourlyAttendance(),
        widget.subjectService.fetchSubjects(),
        widget.marksService.fetchMarks(),
      ].map((future) async {
        try {
          return await future;
        } catch (error) {
          return error;
        }
      }),
    );
    if (!mounted) return;
    setState(() {
      if (results[0] is FetchResult<List<AttendanceRecord>>) {
        _attendance = (results[0] as FetchResult<List<AttendanceRecord>>).data;
      }
      if (results[1] is FetchResult<List<Subject>>) {
        _subjects = (results[1] as FetchResult<List<Subject>>).data;
      }
      if (results[2] is FetchResult<List<CourseMarks>>) {
        _marks = (results[2] as FetchResult<List<CourseMarks>>).data;
      }
      final failures =
          results.whereType<Object>().where((v) => v is! FetchResult).length;
      _error = failures == 3
          ? 'Academic records could not be reached. Pull down to retry.'
          : null;
      _loading = false;
      _refreshing = false;
    });
  }

  int? get _currentSemester {
    final semesters = _subjects
        .map((subject) => subject.semester)
        .where((semester) => semester > 0);
    if (semesters.isEmpty) return null;
    return semesters.reduce(
      (highest, semester) => semester > highest ? semester : highest,
    );
  }

  List<Subject> get _currentSemesterSubjects {
    final semester = _currentSemester;
    if (semester == null) return _subjects;
    return _subjects.where((subject) => subject.semester == semester).toList();
  }

  int get _present => _attendance.fold(0, (sum, day) => sum + day.presentCount);
  int get _absent => _attendance.fold(0, (sum, day) => sum + day.absentCount);
  double? get _attendancePercent {
    final total = _present + _absent;
    return total == 0 ? null : _present / total * 100;
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final percent = _attendancePercent;
    final side = Responsive.dp(context, 20);
    final noData = _loading &&
        _attendance.isEmpty &&
        _subjects.isEmpty &&
        _marks.isEmpty;

    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: AppTheme.crimson,
            backgroundColor: AppTheme.glass,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(
                side,
                Responsive.dp(context, 18),
                side,
                Responsive.dp(context, 130),
              ),
              children: [
                FadeSlideIn(child: _header()),
                const SizedBox(height: 22),
                if (_error != null) ...[
                  _notice(_error!, Icons.cloud_off_rounded),
                ],
                if (noData) ...const [
                  SkeletonBox(height: 200, radius: 28),
                  SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: SkeletonBox(height: 110, radius: 22)),
                      SizedBox(width: 10),
                      Expanded(child: SkeletonBox(height: 110, radius: 22)),
                      SizedBox(width: 10),
                      Expanded(child: SkeletonBox(height: 110, radius: 22)),
                    ],
                  ),
                  SizedBox(height: 26),
                  SkeletonBox(height: 70, radius: 20),
                  SizedBox(height: 10),
                  SkeletonBox(height: 70, radius: 20),
                ] else ...[
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 80),
                    child: _attendanceHero(percent),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 140),
                    child: _toolTiles(percent),
                  ),
                  const SizedBox(height: 30),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: _subjectsSection(),
                  ),
                  const SizedBox(height: 28),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 260),
                    child: _calculatorCard(),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Totals use the hourly history currently loaded. They may not represent the full semester if the ERP returns only partial history.',
                    style: TextStyle(
                      color: AppTheme.white38,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------
  Widget _header() {
    final sem = _currentSemester;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ACADEMICS',
                style: TextStyle(
                  color: AppTheme.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                sem == null ? 'Your semester' : 'Semester $sem',
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: Responsive.sp(context, 30),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.9,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Attendance, subjects and marks at a glance.',
                style: TextStyle(color: AppTheme.white54, fontSize: 12.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        PressableScale(
          onTap: _refreshing ? null : _refresh,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.backgroundSoft,
              border: Border.all(color: AppTheme.outline),
            ),
            child: _refreshing
                ? const Padding(
                    padding: EdgeInsets.all(13),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.crimson,
                    ),
                  )
                : const Icon(Icons.refresh_rounded,
                    color: AppTheme.white70, size: 20),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ATTENDANCE HERO
  // ---------------------------------------------------------------------------
  Widget _attendanceHero(double? percent) {
    final color = percent == null
        ? AppTheme.white54
        : percent >= 75
            ? AppTheme.crimson
            : AppTheme.orange;

    return AppTicketCard(
      onTap: () => context.push(AppRoutes.attendance),
      semanticLabel: 'Attendance summary',
      top: Row(
        children: [
          ProgressRing(
            value: percent == null ? 0 : percent / 100,
            color: color,
            size: Responsive.dp(context, 112),
            stroke: 11,
            child: Text(
              percent == null ? '—' : '\${percent.toStringAsFixed(0)}%',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: Responsive.sp(context, 25),
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attendance',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'From loaded history',
                  style: TextStyle(color: AppTheme.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _countPill('\$_present', 'present', AppTheme.green),
              _countPill('\$_absent', 'absent', AppTheme.orange),
            ],
          ),
          if (percent != null) ...[
            const SizedBox(height: 10),
            StatusChip(
              label: percent >= 75 ? 'On track' : 'Below 75%',
              color: color,
              icon: percent >= 75
                  ? Icons.trending_up_rounded
                  : Icons.warning_amber_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _countPill(String value, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(color: AppTheme.white54, fontSize: 10.5),
            ),
          ],
        ),
      );

  // ---------------------------------------------------------------------------
  // TOOL TILES (bento row)
  // ---------------------------------------------------------------------------
  Widget _toolTiles(double? percent) {
    final tiles = <({IconData icon, String value, String label, String route})>[
      (
        icon: Icons.fact_check_rounded,
        value: percent == null ? 'Open' : '\${percent.toStringAsFixed(0)}%',
        label: 'Attendance',
        route: AppRoutes.attendance,
      ),
      (
        icon: Icons.menu_book_rounded,
        value: '\${_subjects.length}',
        label: 'Subjects',
        route: AppRoutes.subjects,
      ),
      (
        icon: Icons.insights_rounded,
        value: '\${_marks.length}',
        label: 'Marks',
        route: AppRoutes.marks,
      ),
    ];

    return AppListGroup(
      dividerIndent: 68,
      children: [
        for (final tile in tiles)
          AppListTile(
            icon: tile.icon,
            iconColor: AppTheme.white70,
            title: tile.label,
            value: tile.value,
            onTap: () => context.push(tile.route),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SUBJECTS
  // ---------------------------------------------------------------------------
  Widget _subjectsSection() {
    final subjects = _currentSemesterSubjects;
    final sem = _currentSemester;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: sem == null ? 'Your subjects' : 'This semester',
          subtitle: sem == null
              ? 'From your ERP records'
              : 'Semester $sem · ${subjects.length} subjects',
          trailing: subjects.length > 5
              ? TextButton(
                  onPressed: () => context.push(AppRoutes.subjects),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.crimson,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('See all'),
                )
              : null,
        ),
        const SizedBox(height: 14),
        if (_subjects.isEmpty)
          _notice(
            _loading
                ? 'Loading your subjects…'
                : 'No subject records are available yet.',
            Icons.menu_book_outlined,
          )
        else
          for (var i = 0; i < subjects.take(5).length; i++)
            _subjectTile(subjects[i], i),
      ],
    );
  }

  Widget _subjectTile(Subject s, int index) {
    const palette = [
      AppTheme.blue,
      AppTheme.purple,
      AppTheme.orange,
      AppTheme.green,
      AppTheme.crimson,
    ];
    final color = palette[index % palette.length];
    final initial = s.title.isNotEmpty ? s.title[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () => context.push(AppRoutes.subjects),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                initial,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.faculty.isNotEmpty
                        ? '${s.courseCode}  ·  ${s.faculty}'
                        : s.courseCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${s.credits} cr',
                style: const TextStyle(
                  color: AppTheme.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CALCULATOR
  // ---------------------------------------------------------------------------
  Widget _calculatorCard() {
    return PressableScale(
      scale: 0.985,
      onTap: _showCalculator,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.purple.withValues(alpha: 0.16),
              AppTheme.glass,
            ],
          ),
          border: Border.all(color: AppTheme.purple.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.purple.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.calculate_rounded,
                  color: AppTheme.purple, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target calculator',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'How many sessions to reach your goal?',
                    style: TextStyle(color: AppTheme.white54, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.white38),
          ],
        ),
      ),
    );
  }

  void _showCalculator() {
    final present = _present;
    final absent = _absent;
    final total = present + absent;
    final current = total == 0 ? null : present / total * 100;
    var target = 75.0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundSoft,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final reached = current != null && current >= target;
          final needed = (total == 0 || reached)
              ? 0
              : ((target * total - 100 * present) / (100 - target))
                  .ceil()
                  .clamp(0, 100000);

          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              4,
              24,
              MediaQuery.of(context).viewInsets.bottom + 30,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Target calculator',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  total == 0
                      ? 'Not enough history yet.'
                      : 'Now at ${current!.toStringAsFixed(1)}% · $present present, $absent absent',
                  style: const TextStyle(
                    color: AppTheme.white54,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Text(
                      'TARGET',
                      style: TextStyle(
                        color: AppTheme.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${target.round()}%',
                      style: const TextStyle(
                        color: AppTheme.crimson,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.crimson,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: AppTheme.crimson,
                    overlayColor: AppTheme.crimson.withValues(alpha: 0.15),
                    trackHeight: 5,
                  ),
                  child: Slider(
                    min: 50,
                    max: 99,
                    divisions: 49,
                    value: target,
                    onChanged: (v) => setSheetState(() => target = v),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.crimson.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.crimson.withValues(alpha: 0.22),
                    ),
                  ),
                  child: total == 0
                      ? const Text(
                          'Not enough attendance history to calculate a result.',
                          style: TextStyle(color: AppTheme.orange),
                        )
                      : reached
                          ? const Row(
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    color: AppTheme.crimson),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'You have already reached this target.',
                                    style: TextStyle(
                                      color: AppTheme.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$needed',
                                  style: const TextStyle(
                                    color: AppTheme.crimson,
                                    fontSize: 44,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.5,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      'consecutive sessions to attend to reach your target',
                                      style: TextStyle(
                                        color: AppTheme.white70,
                                        fontSize: 12.5,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Assumes every future scheduled session is attended.',
                  style: TextStyle(color: AppTheme.white38, fontSize: 10.5),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _notice(String message, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.white54, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppTheme.white54,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}