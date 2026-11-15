import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app/app_router.dart';
import '../core/cache/data_cache.dart';
import '../core/theme/app_theme.dart';
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
import '../widgets/app_card.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_container.dart';
import '../widgets/section_header.dart';
import '../widgets/ui_kit.dart';

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

  void _showAccountSheet() {
    final auth = context.read<AuthProvider>();
    final student = _dashboard!.student;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppTheme.backgroundSoft,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        void go(String route) {
          Navigator.pop(sheetContext);
          context.go(route);
        }

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Identity: tap to open the full profile
                AppCard(
                  padding: const EdgeInsets.all(16),
                  onTap: () => go(AppRoutes.profile),
                  semanticLabel: 'Open profile',
                  child: Row(
                    children: [
                      GlassAvatar(
                        name: student.name,
                        imageDataUri: auth.studentPhotoDataUri,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              student.department.isNotEmpty
                                  ? student.department
                                  : 'Student account',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.white54,
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'View profile',
                              style: TextStyle(
                                color: AppTheme.crimson,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.white38,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Navigation
                AppListGroup(
                  children: [
                    AppListTile(
                      icon: Icons.school_outlined,
                      title: 'Academic details',
                      subtitle: 'Course, subjects and semester',
                      onTap: () => go(AppRoutes.academics),
                    ),
                    AppListTile(
                      icon: Icons.settings_outlined,
                      title: 'Settings & security',
                      subtitle: 'Linked accounts and passwords',
                      onTap: () => go(AppRoutes.settings),
                    ),
                    // Add Notifications / Help here once their screens exist:
                    // AppListTile(icon: ..., title: ..., onTap: () => go(...)),
                  ],
                ),
                const SizedBox(height: 14),

                // Sign out
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await auth.logout();
                      if (!mounted) return;
                      context.go(AppRoutes.login);
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      'Sign out',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.red,
                      side: BorderSide(
                        color: AppTheme.red.withValues(alpha: 0.7),
                      ),
                      backgroundColor: AppTheme.red.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.surface),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _accountTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? AppTheme.white;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: itemColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: itemColor, size: 21),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: itemColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppTheme.white54, fontSize: 11),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppTheme.white38,
          size: 20,
        ),
      ),
    );
  }

  // DATA (unchanged behaviour)
  // ---------------------------------------------------------------------------
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
      final announcements = await widget.collegeUpdatesService
          .fetchAnnouncements(refresh: refresh);
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
    await Future.wait([_refreshData(), _refreshAnnouncements(refresh: true)]);
  }

  Future<void> _openAnnouncement(CollegeAnnouncement announcement) async {
    final opened = await openAnnouncementLink(announcement.url);
    if (!mounted || opened) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open this announcement link.')),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (_isLoading) {
      content = _buildSkeleton();
    } else if (_error != null || _dashboard == null) {
      content = ErrorView(
        message: _error ?? 'Unable to load dashboard',
        onRetry: _refreshData,
      );
    } else {
      content = _buildContent();
    }

    return Scaffold(
      body: GlassBackground(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: KeyedSubtree(
            key: ValueKey(
              _isLoading ? 'skeleton' : (_error != null ? 'error' : 'content'),
            ),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    final pad = Responsive.dp(context, 20);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 12, width: 140),
            SizedBox(height: 12),
            SkeletonBox(height: 30, width: 240),
            SizedBox(height: 26),
            SkeletonBox(height: 190, radius: 26),
            SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: SkeletonBox(height: 88, radius: 20)),
                SizedBox(width: 10),
                Expanded(child: SkeletonBox(height: 88, radius: 20)),
                SizedBox(width: 10),
                Expanded(child: SkeletonBox(height: 88, radius: 20)),
                SizedBox(width: 10),
                Expanded(child: SkeletonBox(height: 88, radius: 20)),
              ],
            ),
            SizedBox(height: 26),
            SkeletonBox(height: 72, radius: 20),
            SizedBox(height: 10),
            SkeletonBox(height: 72, radius: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final dashboard = _dashboard!;
    final todayRecord = _getTodayAttendance();
    final sidePad = Responsive.dp(context, 20);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refreshAll,
        color: AppTheme.crimson,
        backgroundColor: AppTheme.glass,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                sidePad,
                Responsive.dp(context, 18),
                sidePad,
                Responsive.dp(context, 130),
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeSlideIn(child: _buildHeader(dashboard)),
                  const SizedBox(height: 22),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 80),
                    child: _buildHeroCard(todayRecord),
                  ),
                  const SizedBox(height: 22),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 160),
                    child: _buildQuickAccess(),
                  ),
                  const SizedBox(height: 30),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 240),
                    child: _buildAnnouncementsSection(),
                  ),
                  const SizedBox(height: 28),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 320),
                    child: _buildRecentLogsSection(),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeader(DashboardModel dashboard) {
    final student = dashboard.student;
    final firstName = student.name.isNotEmpty
        ? student.name.split(' ').first
        : 'Student';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatTodayDate().toUpperCase(),
                style: TextStyle(
                  color: AppTheme.white54,
                  fontSize: Responsive.sp(context, 11),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _greeting(),
                style: TextStyle(
                  color: AppTheme.white70,
                  fontSize: Responsive.sp(context, 15),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: Responsive.sp(context, 30),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.9,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        PressableScale(
          onTap: _showAccountSheet,
          child: GlassAvatar(
            name: student.name,
            imageDataUri: context.watch<AuthProvider>().studentPhotoDataUri,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HERO: attendance ring + today's hours
  // ---------------------------------------------------------------------------
  Widget _buildHeroCard(AttendanceRecord? record) {
    final hasSummary = _attendanceSummary != null;
    final percentage = _getAttendancePercentage();
    final onTrack = percentage >= 75;
    final color = onTrack ? AppTheme.crimson : AppTheme.red;
    final hours = record?.hours.take(8).toList() ?? [];

    return AppTicketCard(
      onTap: () => context.go(AppRoutes.attendance),
      semanticLabel: 'Overall attendance and today’s attendance hours',
      top: Row(
        children: [
          ProgressRing(
            value: hasSummary ? percentage / 100 : 0,
            color: color,
            size: Responsive.dp(context, 104),
            stroke: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasSummary ? percentage.toStringAsFixed(0) : '—',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: Responsive.sp(context, 28),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
                const Text(
                  'PERCENT',
                  style: TextStyle(
                    color: AppTheme.white54,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall attendance',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Minimum requirement 75%',
                  style: TextStyle(color: AppTheme.white54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                if (hasSummary)
                  StatusChip(
                    label: onTrack ? 'On track' : 'Below target',
                    color: color,
                    icon: onTrack
                        ? Icons.trending_up_rounded
                        : Icons.warning_amber_rounded,
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.white38),
        ],
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.today_rounded,
                size: 15,
                color: AppTheme.white54,
              ),
              const SizedBox(width: 7),
              const Text(
                'TODAY',
                style: TextStyle(
                  color: AppTheme.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  _todaySummary(record),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (hours.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < hours.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(child: _hourTile(hours[i])),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _todaySummary(AttendanceRecord? record) {
    if (record == null) return 'No record yet';
    final scheduled = record.scheduledCount;
    if (scheduled == 0) return 'No classes';
    return '${record.presentCount}/$scheduled present';
  }

  Widget _hourTile(AttendanceHour hour) {
    final (color, icon) = _statusStyle(hour.status);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(height: 4),
          Text(
            'H${hour.hour}',
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData) _statusStyle(AttendanceStatus status) => switch (status) {
    AttendanceStatus.present => (AppTheme.green, Icons.check_rounded),
    AttendanceStatus.absent => (AppTheme.red, Icons.close_rounded),
    AttendanceStatus.notScheduled => (AppTheme.white30, Icons.remove_rounded),
  };

  // ---------------------------------------------------------------------------
  // QUICK ACCESS (app-icon style grid)
  // ---------------------------------------------------------------------------
  Widget _buildQuickAccess() {
    final items = <({IconData icon, String label, Color color, String route})>[
      (
        icon: Icons.fact_check_rounded,
        label: 'Attendance',
        color: AppTheme.crimson,
        route: AppRoutes.attendance,
      ),
      (
        icon: Icons.menu_book_rounded,
        label: 'Subjects',
        color: AppTheme.blue,
        route: AppRoutes.subjects,
      ),
      (
        icon: Icons.grading_rounded,
        label: 'Marks',
        color: AppTheme.purple,
        route: AppRoutes.marks,
      ),
      (
        icon: Icons.calendar_month_rounded,
        label: 'Calendar',
        color: AppTheme.orange,
        route: AppRoutes.calendar,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: PressableScale(
              onTap: () => context.go(items[i].route),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: items[i].color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        items[i].icon,
                        color: items[i].color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      items[i].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ANNOUNCEMENTS
  // ---------------------------------------------------------------------------
  Widget _buildAnnouncementsSection() {
    final visible = _announcements.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Campus updates',
          subtitle: 'Notices from Loyola College',
          trailing: TextButton(
            onPressed: () => context.push(AppRoutes.updates),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.crimson,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('See all'),
                SizedBox(width: 3),
                Icon(Icons.arrow_forward_rounded, size: 15),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_announcementsLoading && _announcements.isEmpty) ...const [
          SkeletonBox(height: 74, radius: 20),
          SizedBox(height: 10),
          SkeletonBox(height: 74, radius: 20),
        ] else if (_announcementsError != null && _announcements.isEmpty)
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: AppTheme.white54,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Updates are unavailable right now.',
                    style: TextStyle(color: AppTheme.white54, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () => _refreshAnnouncements(refresh: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (visible.isEmpty)
          const GlassContainer(
            padding: EdgeInsets.all(18),
            child: Text(
              'No campus announcements are available.',
              style: TextStyle(color: AppTheme.white54, fontSize: 13),
            ),
          )
        else
          ...visible.map(
            (a) => AnnouncementCard(
              announcement: a,
              onTap: () => _openAnnouncement(a),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // RECENT LOGS
  // ---------------------------------------------------------------------------
  Widget _buildRecentLogsSection() {
    final today = _getTodayAttendance();
    final recent = _attendance.where((r) => r != today).take(5).toList();
    if (recent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent days',
          subtitle: 'Your last few attendance logs',
          trailing: TextButton(
            onPressed: () => context.go(AppRoutes.attendance),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.crimson,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Details'),
          ),
        ),
        const SizedBox(height: 14),
        GlassContainer(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.dp(context, 18),
            vertical: 8,
          ),
          child: Column(
            children: [
              for (var i = 0; i < recent.length; i++) ...[
                _buildRecentLogItem(recent[i]),
                if (i < recent.length - 1)
                  Divider(
                    color: AppTheme.white.withValues(alpha: 0.07),
                    height: 1,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentLogItem(AttendanceRecord record) {
    final hours = record.hours.take(8).toList();
    final hasClasses = record.scheduledCount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatRecordDate(record.date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  (record.dayOrder ?? 0) > 0
                      ? 'Day order ${record.dayOrder}'
                      : 'No schedule',
                  style: const TextStyle(
                    color: AppTheme.white54,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          if (hasClasses)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final h in hours)
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Container(
                      width: 9,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _statusStyle(h.status).$1.withValues(
                          alpha: h.status == AttendanceStatus.notScheduled
                              ? 0.35
                              : 0.9,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
              ],
            )
          else
            const Text(
              '—',
              style: TextStyle(color: AppTheme.white30, fontSize: 16),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
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
    return null;
  }

  static const _weekdaysLong = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _weekdaysShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const _months = [
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

  String _formatTodayDate() {
    final now = DateTime.now();
    return '${_weekdaysLong[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}';
  }

  String _formatRecordDate(String dateStr) {
    try {
      final parts = dateStr.trim().split(RegExp(r'[-/]'));
      if (parts.length >= 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final date = DateTime(year < 100 ? year + 2000 : year, month, day);
        return '${_weekdaysShort[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]}';
      }
    } catch (_) {}
    return dateStr;
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

// =============================================================================
// AVATAR
// =============================================================================
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
          color: AppTheme.background,
          fontSize: Responsive.sp(context, 20),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    final size = Responsive.dp(context, 50);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.crimson,
        border: Border.all(
          color: AppTheme.white.withValues(alpha: 0.22),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.crimson.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(child: _buildPhotoOrInitial(context, initial, size)),
    );
  }
}
