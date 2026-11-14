import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_router.dart';
import '../core/constants/app_colors.dart';
import '../core/cache/data_cache.dart';
import '../models/attendance_model.dart';
import '../models/marks_model.dart';
import '../models/subject_model.dart';
import '../services/attendance_service.dart';
import '../services/marks_service.dart';
import '../services/subject_service.dart';

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
        if (_attendance.isNotEmpty || _subjects.isNotEmpty || _marks.isNotEmpty) {
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
    final results = await Future.wait([
      widget.attendanceService.fetchHourlyAttendance(),
      widget.subjectService.fetchSubjects(),
      widget.marksService.fetchMarks(),
    ].map((future) async {
      try { return await future; } catch (error) { return error; }
    }));
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
      final failures = results.whereType<Object>().where((v) => v is! FetchResult).length;
      _error = failures == 3 ? 'Academic records could not be reached. Pull down to retry.' : null;
      _loading = false;
      _refreshing = false;
    });
  }

  int get _present => _attendance.fold(0, (sum, day) => sum + day.presentCount);
  int get _absent => _attendance.fold(0, (sum, day) => sum + day.absentCount);
  double? get _attendancePercent {
    final total = _present + _absent;
    return total == 0 ? null : _present / total * 100;
  }

  @override
  Widget build(BuildContext context) {
    final percent = _attendancePercent;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.crimson,
          backgroundColor: AppColors.glass,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            children: [
              _topBar(),
              const SizedBox(height: 24),
              const Text('Your academic workspace', style: TextStyle(color: AppColors.white, fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
              const SizedBox(height: 7),
              const Text('Everything you need to stay on top of the semester.', style: TextStyle(color: AppColors.white54, fontSize: 13, height: 1.45)),
              const SizedBox(height: 22),
              if (_loading) const LinearProgressIndicator(minHeight: 2),
              if (_error != null) _notice(_error!, Icons.cloud_off_rounded),
              _attendanceCard(percent),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _statCard('Subjects', _loading ? '—' : '${_subjects.length}', Icons.menu_book_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _statCard('Assessments', _loading ? '—' : '${_marks.length}', Icons.assignment_turned_in_outlined)),
              ]),
              const SizedBox(height: 24),
              _sectionTitle('Your study tools', 'Jump straight to what matters'),
              const SizedBox(height: 12),
              _actionTile(
                icon: Icons.fact_check_rounded,
                title: 'Attendance',
                subtitle: 'Daily records, subject-wise status and history',
                trailing: percent == null ? 'Open' : '${percent.toStringAsFixed(1)}%',
                onTap: () => context.push(AppRoutes.attendance),
              ),
              _actionTile(
                icon: Icons.menu_book_rounded,
                title: 'Subjects',
                subtitle: 'Courses, credits and faculty information',
                trailing: '${_subjects.length}',
                onTap: () => context.push(AppRoutes.subjects),
              ),
              _actionTile(
                icon: Icons.insights_rounded,
                title: 'Internal marks',
                subtitle: 'CIA components and published totals',
                trailing: '${_marks.length}',
                onTap: () => context.push(AppRoutes.marks),
              ),
              const SizedBox(height: 24),
              _sectionTitle('Your subjects', 'From your ERP records'),
              const SizedBox(height: 12),
              if (_subjects.isEmpty)
                _notice(_loading ? 'Loading your subjects…' : 'No subject records are available yet.', Icons.menu_book_outlined)
              else
                ..._subjects.take(5).map(_subjectTile),
              if (_subjects.length > 5)
                TextButton(onPressed: () => context.push(AppRoutes.subjects), child: const Text('View all subjects')),
              const SizedBox(height: 24),
              _sectionTitle('Quick insight', 'Calculated from the records currently loaded'),
              const SizedBox(height: 12),
              _calculatorCard(),
              const SizedBox(height: 8),
              Text('Attendance totals above use the available hourly history. They may not represent the complete semester total if the ERP returns only a partial history.', style: TextStyle(color: AppColors.white38, fontSize: 11, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() => Row(children: [
    Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.crimson, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.school_rounded, color: AppColors.background, size: 21)),
    const SizedBox(width: 11),
    const Expanded(child: Text('ACADEMICS', style: TextStyle(color: AppColors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.8))),
    IconButton(onPressed: _refreshing ? null : _refresh, tooltip: 'Refresh records', icon: Icon(Icons.refresh_rounded, color: _refreshing ? AppColors.white38 : AppColors.white70)),
  ]);

  Widget _attendanceCard(double? percent) {
    final value = percent == null ? '—' : '${percent.toStringAsFixed(1)}%';
    final color = percent == null ? AppColors.white54 : percent >= 75 ? AppColors.crimson : AppColors.orange;
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF263A32), Color(0xFF17251F)]),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppColors.crimson.withValues(alpha: .18)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Expanded(child: Text('ATTENDANCE SNAPSHOT', style: TextStyle(color: AppColors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.3))), Icon(Icons.north_east_rounded, color: AppColors.crimson, size: 18)]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(value, style: TextStyle(color: color, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
          const SizedBox(width: 9),
          const Padding(padding: EdgeInsets.only(bottom: 7), child: Text('from loaded history', style: TextStyle(color: AppColors.white54, fontSize: 11))),
        ]),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: percent == null ? 0 : (percent / 100).clamp(0, 1).toDouble(), minHeight: 7, backgroundColor: Colors.white12, color: color)),
        const SizedBox(height: 13),
        Row(children: [
          _legend('$_present present', AppColors.crimson),
          const SizedBox(width: 18),
          _legend('$_absent absent', AppColors.orange),
          const Spacer(),
          TextButton(onPressed: () => context.push(AppRoutes.attendance), child: const Text('Details')),
        ]),
      ]),
    );
  }

  Widget _legend(String label, Color color) => Row(children: [Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 6), Text(label, style: const TextStyle(color: AppColors.white70, fontSize: 11))]);

  Widget _statCard(String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: AppColors.backgroundSoft, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.outline)),
    child: Row(children: [Icon(icon, color: AppColors.crimson, size: 19), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w800)), Text(label, style: const TextStyle(color: AppColors.white54, fontSize: 11))]))]),
  );

  Widget _sectionTitle(String title, String subtitle) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w800)),
    const SizedBox(height: 3),
    Text(subtitle, style: const TextStyle(color: AppColors.white54, fontSize: 11)),
  ]);

  Widget _actionTile({required IconData icon, required String title, required String subtitle, required String trailing, required VoidCallback onTap}) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    decoration: BoxDecoration(color: AppColors.backgroundSoft, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppColors.outline)),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.crimson.withValues(alpha: .11), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: AppColors.crimson, size: 20)),
      title: Text(title, style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w700)),
      subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitle, style: const TextStyle(color: AppColors.white54, fontSize: 11))),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(trailing, style: const TextStyle(color: AppColors.crimson, fontSize: 12, fontWeight: FontWeight.w800)), const SizedBox(width: 5), const Icon(Icons.chevron_right_rounded, color: AppColors.white38)]),
    ),
  );

  Widget _subjectTile(Subject subject) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.backgroundSoft, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.outline)),
    child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: .12), borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.book_outlined, color: AppColors.blue, size: 18)),
      const SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(subject.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text('${subject.courseCode}  •  ${subject.credits} credits', style: const TextStyle(color: AppColors.white54, fontSize: 10))])),
      Text('Sem ${subject.semester}', style: const TextStyle(color: AppColors.white38, fontSize: 10)),
    ]),
  );

  Widget _calculatorCard() {
    return InkWell(
      onTap: _showCalculator,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.glass, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.outline)),
        child: const Row(children: [
          Icon(Icons.calculate_rounded, color: AppColors.crimson, size: 25),
          SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Attendance target calculator', style: TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text('Estimate classes needed to reach your target', style: TextStyle(color: AppColors.white54, fontSize: 11)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, color: AppColors.white38, size: 14),
        ]),
      ),
    );
  }

  void _showCalculator() {
    final present = _present;
    final absent = _absent;
    final total = present + absent;
    final controller = TextEditingController(text: '75');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundSoft,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (sheetContext) => StatefulBuilder(builder: (context, setSheetState) {
        final target = double.tryParse(controller.text) ?? 75;
        final current = total == 0 ? null : present / total * 100;
        final needed = target <= 0 || target >= 100 || total == 0 || current! >= target
            ? 0
            : ((target * total - 100 * present) / (100 - target)).ceil().clamp(0, 100000);
        return Padding(
          padding: EdgeInsets.fromLTRB(22, 22, 22, MediaQuery.of(context).viewInsets.bottom + 28),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Attendance calculator', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Based on $present present and $absent absent sessions in loaded history.', style: const TextStyle(color: AppColors.white54, fontSize: 12)),
            const SizedBox(height: 18),
            TextField(controller: controller, keyboardType: TextInputType.number, onChanged: (_) => setSheetState(() {}), decoration: const InputDecoration(labelText: 'Target attendance (%)', suffixText: '%')),
            const SizedBox(height: 16),
            if (total == 0)
              const Text('Not enough attendance history to calculate a result.', style: TextStyle(color: AppColors.orange))
            else if (target <= 0 || target >= 100)
              const Text('Enter a target greater than 0 and below 100.', style: TextStyle(color: AppColors.orange))
            else
              Text(current! >= target ? 'You have already reached your target.' : 'Attend the next $needed consecutive sessions to reach ${target.toStringAsFixed(0)}%.', style: const TextStyle(color: AppColors.crimson, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Assumes every future scheduled session is attended and no additional absences occur.', style: TextStyle(color: AppColors.white38, fontSize: 10)),
          ]),
        );
      }),
    ).whenComplete(controller.dispose);
  }

  Widget _notice(String message, IconData icon) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.glass, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.outline)),
    child: Row(children: [Icon(icon, color: AppColors.white54, size: 18), const SizedBox(width: 10), Expanded(child: Text(message, style: const TextStyle(color: AppColors.white54, fontSize: 12)))]),
  );
}
