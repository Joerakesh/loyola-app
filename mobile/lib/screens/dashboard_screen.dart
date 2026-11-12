import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app/app_router.dart';
import '../core/cache/data_cache.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/responsive.dart';
import '../models/attendance_model.dart';
import '../models/college_announcement.dart';
import '../models/dashboard_model.dart';
import '../services/attendance_service.dart';
import '../services/auth_provider.dart';
import '../services/college_updates_service.dart';
import '../services/dashboard_service.dart';
import '../utils/announcement_links.dart';
import '../widgets/announcement_card.dart';
import '../widgets/app_state_views.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_container.dart';
import '../widgets/section_header.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.dashboardService,
    required this.attendanceService,
    required this.collegeUpdatesService,
  });

  final DashboardService dashboardService;
  final AttendanceService attendanceService;
  final CollegeUpdatesService collegeUpdatesService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardModel? _dashboard;
  List<AttendanceRecord> _attendance = [];
  bool _isLoading = true;
  String? _error;
  dynamic _attendanceSummary;
  List<CollegeAnnouncement> _announcements = [];
  bool _announcementsLoading = true;
  String? _announcementsError;

  @override
  void initState() {
    super.initState();
    _loadCached();
    _refreshData();
    _refreshAnnouncements();
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

  Future<void> _refreshAnnouncements({bool refresh = false}) async {
    setState(() {
      _announcementsLoading = true;
      _announcementsError = null;
    });

    try {
      final announcements = await widget.collegeUpdatesService.fetchAnnouncements(
        refresh: refresh,
      );
      if (!mounted) return;
      setState(() {
        _announcements = announcements;
        _announcementsLoading = false;
        _announcementsError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _announcementsLoading = false;
        _announcementsError = error.toString();
      });
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _refreshData(),
      _refreshAnnouncements(refresh: true),
    ]);
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
        onRefresh: _refreshAll,
        color: AppColors.white,
        backgroundColor: AppColors.glass,
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
                  _buildAcademicOverview(todayRecord),
                  const SizedBox(height: 26),
                  _buildAnnouncementsSection(),
                  const SizedBox(height: 24),
                  _buildRecentLogsSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAnnouncement(CollegeAnnouncement announcement) async {
    final opened = await openAnnouncementLink(announcement.url);
    if (!mounted || opened) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open this announcement link.')),
    );
  }

  Widget _buildAnnouncementsSection() {
    final visibleAnnouncements = _announcements.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Campus announcements',
          subtitle: 'Notices and documents from Loyola College',
          trailing: TextButton.icon(
            onPressed: () => context.push(AppRoutes.updates),
            icon: const Icon(Icons.arrow_outward_rounded, size: 15),
            label: const Text('All updates'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.crimson,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_announcementsLoading && _announcements.isEmpty)
          const GlassContainer(
            padding: EdgeInsets.all(18),
            child: Row(
              children: [
                SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text(
                  'Loading campus updates…',
                  style: TextStyle(color: AppColors.white54, fontSize: 13),
                ),
              ],
            ),
          )
        else if (_announcementsError != null && _announcements.isEmpty)
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Campus announcements are unavailable right now.',
                    style: TextStyle(color: AppColors.white54, fontSize: 13),
                  ),
                ),
                IconButton(
                  tooltip: 'Retry announcements',
                  onPressed: () => _refreshAnnouncements(refresh: true),
                  icon: const Icon(Icons.refresh_rounded),
                  color: AppColors.crimson,
                ),
              ],
            ),
          )
        else if (visibleAnnouncements.isEmpty)
          const GlassContainer(
            padding: EdgeInsets.all(18),
            child: Text(
              'No campus announcements are available.',
              style: TextStyle(color: AppColors.white54, fontSize: 13),
            ),
          )
        else
          ...visibleAnnouncements.map(
            (announcement) => AnnouncementCard(
              announcement: announcement,
              onTap: () => _openAnnouncement(announcement),
            ),
          ),
      ],
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
          Row(children: [
            GlassAvatar(
              name: student.name,
              imageDataUri: context.watch<AuthProvider>().studentPhotoDataUri,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildAcademicOverview(AttendanceRecord? record) {
    final hours = record?.hours.take(5).toList() ?? [];
    final percentage = _getAttendancePercentage();
    final progressColor = percentage >= 75 ? AppColors.crimson : AppColors.red;
    final scheduledHours = hours
        .where((hour) => hour.status != AttendanceStatus.notScheduled)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Academic overview',
          subtitle: 'Attendance and today’s schedule',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'Attendance',
                value: _attendanceSummary == null
                    ? '—'
                    : '${percentage.toStringAsFixed(1)}%',
                caption: percentage >= 75 ? 'On track' : 'Below 75% target',
                icon: Icons.track_changes_rounded,
                accent: progressColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                label: 'Today',
                value: (record?.dayOrder ?? 0) > 0
                    ? 'Day ${record!.dayOrder}'
                    : 'No class',
                caption: '$scheduledHours scheduled sessions',
                icon: Icons.calendar_month_rounded,
                accent: AppColors.gold,
              ),
            ),
          ],
        ),
        if (hours.isNotEmpty) ...[
          const SizedBox(height: 12),
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Wrap(
              spacing: 18,
              runSpacing: 10,
              children: hours.map(_buildHourStatusPill).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String caption,
    required IconData icon,
    required Color accent,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.white,
              fontSize: Responsive.sp(context, 23),
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: Responsive.sp(context, 11),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourStatusPill(AttendanceHour hour) {
    Color color;
    IconData icon;

    switch (hour.status) {
      case AttendanceStatus.present:
        color = AppColors.green;
        icon = Icons.task_alt_rounded;
        break;
      case AttendanceStatus.absent:
        color = AppColors.red;
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
                    color = AppColors.green;
                    icon = Icons.task_alt_rounded;
                    break;
                  case AttendanceStatus.absent:
                    color = AppColors.red;
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
                (year != null && year < 100 && year + 2000 == now.year))) {
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
  const GlassAvatar({super.key, required this.name, this.imageDataUri});

  final String name;
  final String? imageDataUri;

  Widget _buildPhotoOrInitial(
    BuildContext context,
    String initial,
    double size,
  ) {
    final value = imageDataUri?.trim();
    if (value != null && value.startsWith('data:image/')) {
      try {
        final bytes = base64Decode(value.substring(value.indexOf(',') + 1));
        return Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initial(context, initial),
        );
      } on FormatException {
        return _initial(context, initial);
      }
    }
    return _initial(context, initial);
  }

  Widget _initial(BuildContext context, String initial) {
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.white,
          fontSize: Responsive.sp(context, 20),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    final size = Responsive.dp(context, 48);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.crimson,
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.crimson.withValues(alpha: 0.26),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: _buildPhotoOrInitial(context, initial, size),
      ),
    );
  }
}
