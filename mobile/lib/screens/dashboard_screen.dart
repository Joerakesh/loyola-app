import 'package:flutter/material.dart';

import '../core/cache/data_cache.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/responsive.dart';
import '../models/attendance_model.dart';
import '../models/dashboard_model.dart';
import '../services/attendance_service.dart';
import '../services/dashboard_service.dart';
import '../widgets/app_state_views.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_container.dart';
import '../widgets/section_header.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.dashboardService,
    required this.attendanceService,
  });

  final DashboardService dashboardService;
  final AttendanceService attendanceService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardModel? _dashboard;
  List<AttendanceRecord> _attendance = [];
  bool _isLoading = true;
  String? _error;
  dynamic _attendanceSummary;

  @override
  void initState() {
    super.initState();
    _loadCached();
    _refreshData();
  }

  double _getAttendancePercentage() {
    if (_attendanceSummary == null) return 0.0;

    if (_attendanceSummary is num) {
      return (_attendanceSummary as num).toDouble();
    }

    if (_attendanceSummary is Map<String, dynamic>) {
      final data = _attendanceSummary as Map<String, dynamic>;
      final value =
          data['percentage'] ??
          data['attendancePercentage'] ??
          data['percentageValue'];

      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }

  Future<void> _loadCached() async {
    try {
      final results = await Future.wait([
        widget.dashboardService.getCachedDashboard(),
        widget.attendanceService.getCachedHourlyAttendance(),
        widget.attendanceService.getCachedAttendanceSummary(),
      ]);

      if (!mounted) return;

      setState(() {
        final dashboard = results[0] as DashboardModel?;
        if (dashboard != null) {
          _dashboard = dashboard;
          _isLoading = false;
          _error = null;
        }
        final attendance = results[1] as List<AttendanceRecord>?;
        if (attendance != null) _attendance = attendance;
        final summary = results[2];
        if (summary != null) _attendanceSummary = summary;
      });
    } catch (_) {}
  }

  Future<void> _refreshData() async {
    try {
      final results = await Future.wait([
        widget.dashboardService.fetchDashboard(),
        widget.attendanceService.fetchHourlyAttendance(),
        widget.attendanceService.fetchAttendanceSummary(),
      ]);

      if (!mounted) return;

      setState(() {
        final dashboard = results[0] as FetchResult<DashboardModel>;
        if (dashboard.changed) _dashboard = dashboard.data;

        final attendance = results[1] as FetchResult<List<AttendanceRecord>>;
        if (attendance.changed) _attendance = attendance.data;

        final summary = results[2];
        if (summary.changed) _attendanceSummary = summary.data;

        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (_dashboard == null) {
          _error = error.toString();
          _isLoading = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _isLoading
        ? const LoadingView()
        : (_error != null || _dashboard == null)
        ? ErrorView(
            message: _error ?? 'Unable to load dashboard',
            onRetry: _refreshData,
          )
        : _buildContent();

    return Scaffold(body: GlassBackground(child: content));
  }

  Widget _buildContent() {
    final dashboard = _dashboard!;
    final todayRecord = _getTodayAttendance();
    final sidePad = Responsive.dp(context, 20);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.white,
        backgroundColor: Colors.black45,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(dashboard)),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                sidePad,
                10,
                sidePad,
                Responsive.dp(context, 130),
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeroCard(todayRecord),
                  const SizedBox(height: 28),
                  _buildRecentLogsSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(DashboardModel dashboard) {
    final student = dashboard.student;
    final firstName = student.name.isNotEmpty
        ? student.name.split(' ').first
        : 'Student';

    return Padding(
      padding: EdgeInsets.all(Responsive.dp(context, 20)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatTodayDate()} • $firstName'.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.white54,
                    fontSize: Responsive.sp(context, 11),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_greeting()}!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: Responsive.sp(context, 28),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Row(children: [GlassAvatar(name: student.name)]),
        ],
      ),
    );
  }

  Widget _buildHeroCard(AttendanceRecord? record) {
    final dayOrder = record?.dayOrder ?? 0;
    final hours = record?.hours.take(5).toList() ?? [];
    final percentage = _getAttendancePercentage();
    final progressColor = percentage >= 75
        ? const Color(0xFF9D84FF)
        : const Color(0xFFFF8484);
    final compact = Responsive.isCompact(context);
    final ringSize = Responsive.dp(context, compact ? 70 : 85);

    return GlassContainer(
      padding: EdgeInsets.all(Responsive.dp(context, 24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Attendance",
                      style: TextStyle(
                        color: AppColors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dayOrder > 0 ? 'Day Order $dayOrder' : 'No Schedule',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: Responsive.sp(context, 24),
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hours.isNotEmpty
                          ? 'Keep up the good work! 🚀'
                          : 'Enjoy your day off ✨',
                      style: TextStyle(
                        color: AppColors.white54,
                        fontSize: Responsive.sp(context, 13),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: ringSize,
                width: ringSize,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: (percentage / 100).clamp(0.0, 1.0),
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      backgroundColor:
                          AppColors.white.withValues(alpha: 0.05),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                    Center(
                      child: Text(
                        '${percentage.toDouble()}%',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: Responsive.sp(context, 20),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (hours.isNotEmpty) ...[
            const SizedBox(height: 28),
            Container(
              height: 1,
              color: AppColors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: hours.map((h) => _buildHourStatusPill(h)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHourStatusPill(AttendanceHour hour) {
    Color color;
    IconData icon;

    switch (hour.status) {
      case AttendanceStatus.present:
        color = const Color(0xFF5ED5A8);
        icon = Icons.task_alt_rounded;
        break;
      case AttendanceStatus.absent:
        color = const Color(0xFFFF7A7A);
        icon = Icons.highlight_off_rounded;
        break;
      case AttendanceStatus.notScheduled:
        color = AppColors.white30;
        icon = Icons.more_horiz_rounded;
        break;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          'H${hour.hour}',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // --- NEW: Recent Logs Section ---
  Widget _buildRecentLogsSection() {
    final today = _getTodayAttendance();
    // Exclude today's record and take the next 4 most recent records
    final recentRecords = _attendance.where((r) => r != today).take(5).toList();

    if (recentRecords.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recent Logs'),
        const SizedBox(height: 14),
        GlassContainer(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.dp(context, 20),
            vertical: 12,
          ),
          child: Column(
            children: recentRecords.asMap().entries.map((entry) {
              final index = entry.key;
              final record = entry.value;
              return Column(
                children: [
                  _buildRecentLogItem(record),
                  if (index < recentRecords.length - 1)
                    Divider(
                      color: AppColors.white.withValues(alpha: 0.1),
                      height: 24,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentLogItem(AttendanceRecord record) {
    final formattedDate = _formatRecordDate(record.date);
    final hours = record.hours.take(5).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formattedDate,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                (record.dayOrder ?? 0) > 0
                    ? 'Day Order ${record.dayOrder}'
                    : 'No Schedule',
                style: const TextStyle(
                  color: AppColors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (hours.isNotEmpty)
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: hours.map((h) {
                Color color;
                IconData icon;
                switch (h.status) {
                  case AttendanceStatus.present:
                    color = const Color(0xFF5ED5A8);
                    icon = Icons.task_alt_rounded;
                    break;
                  case AttendanceStatus.absent:
                    color = const Color(0xFFFF7A7A);
                    icon = Icons.highlight_off_rounded;
                    break;
                  case AttendanceStatus.notScheduled:
                    color = AppColors.white30;
                    icon = Icons.more_horiz_rounded;
                    break;
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(icon, color: color, size: 15),
                );
              }).toList(),
            ),
          )
        else
          const Text(
            '--',
            style: TextStyle(color: AppColors.white30, fontSize: 16),
          ),
      ],
    );
  }

  // --- Helpers ---
  AttendanceRecord? _getTodayAttendance() {
    final now = DateTime.now();
    for (final record in _attendance) {
      final parts = record.date.trim().split(RegExp(r'[-/]'));
      if (parts.length >= 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day == now.day &&
            month == now.month &&
            ((year != null && year == now.year) ||
                (year != null &&
                    year < 100 &&
                    year + 2000 == now.year))) {
          return record;
        }
      }
    }
    return _attendance.isNotEmpty ? _attendance.first : null;
  }

  String _formatTodayDate() {
    final now = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  String _formatRecordDate(String dateStr) {
    try {
      final parts = dateStr.trim().split(RegExp(r'[-/]'));
      if (parts.length >= 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final date = DateTime(year < 100 ? year + 2000 : year, month, day);

        const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];

        return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
      }
    } catch (_) {}
    return dateStr;
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

class GlassAvatar extends StatelessWidget {
  const GlassAvatar({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    final size = Responsive.dp(context, 48);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF9D84FF),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9D84FF).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: AppColors.white,
            fontSize: Responsive.sp(context, 20),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
