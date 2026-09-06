import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/cache/data_cache.dart';
import '../core/constants/app_colors.dart';
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
    if (_attendanceSummary == null) {
      return 0.0;
    }

    // Temporary handling until we confirm
    // the exact JSON structure of the summary API.
    if (_attendanceSummary is num) {
      return (_attendanceSummary as num).toDouble();
    }

    if (_attendanceSummary is Map<String, dynamic>) {
      final data = _attendanceSummary as Map<String, dynamic>;

      final value =
          data['percentage'] ??
          data['attendancePercentage'] ??
          data['percentageValue'];

      if (value is num) {
        return value.toDouble();
      }

      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
    }

    return 0.0;
  }

  // Show whatever is cached instantly, then the refresh will reconcile
  // the versions and update only what actually changed.
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
    } catch (_) {
      // Cache read failures should never block the normal flow.
    }
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
      // Show the error only when there is nothing cached to fall back on.
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
        ? ErrorView(message: _error ?? 'Unable to load dashboard', onRetry: _refreshData)
        : _buildContent();

    return Scaffold(
      body: GlassBackground(child: content),
    );
  }

  Widget _buildContent() {
    final dashboard = _dashboard!;
    final todayRecord = _getTodayAttendance();

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
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 130),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildTodayCard(todayRecord),
                  const SizedBox(height: 24),
                  _buildQuickAccessSection(),
                  const SizedBox(height: 24),
                  _buildFeesAndDocsGrid(dashboard),
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

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting().toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  student.name.isEmpty ? 'Student' : student.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                if (student.department.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    student.department,
                    style: const TextStyle(
                      color: AppColors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          GlassAvatar(name: student.name),
        ],
      ),
    );
  }

  Widget _buildTodayCard(AttendanceRecord? record) {
    final dayOrder = record?.dayOrder ?? 0;
    final hours = record?.hours.take(5).toList() ?? [];

    final percentage = _getAttendancePercentage();

    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.crimson.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          dayOrder > 0 ? 'DAY ORDER $dayOrder' : 'NO DAY ORDER',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTodayDate(),
                        style: const TextStyle(
                          color: AppColors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Today's Attendance",
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              _buildPercentageBadge(percentage),
            ],
          ),
          const SizedBox(height: 20),
          if (hours.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No sessions scheduled for today',
                  style: TextStyle(color: AppColors.white54),
                ),
              ),
            )
          else ...[
            Row(
              children: hours
                  .map(
                    (h) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildHourStatusPill(h),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage >= 75
                      ? const Color(0xFF34C759)
                      : const Color(0xFFFF3B30),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPercentageBadge(double percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.15)),
      ),
      child: Text(
        '${percentage.toStringAsFixed(2)}%',
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildHourStatusPill(AttendanceHour hour) {
    Color color;
    IconData icon;

    switch (hour.status) {
      case AttendanceStatus.present:
        color = AppColors.green;
        icon = Icons.check_rounded;
        break;
      case AttendanceStatus.absent:
        color = AppColors.red;
        icon = Icons.close_rounded;
        break;
      case AttendanceStatus.notScheduled:
        color = AppColors.white30;
        icon = Icons.horizontal_rule_rounded;
        break;
    }

    return Column(
      children: [
        Text(
          'H${hour.hour}',
          style: const TextStyle(
            color: AppColors.white60,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Center(child: Icon(icon, color: color, size: 18)),
        ),
      ],
    );
  }

  Widget _buildQuickAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.4,
          children: [
            _buildGlassTile(
              icon: Icons.assessment_rounded,
              title: 'Marks',
              subtitle: 'CIA breakdown',
              color: AppColors.orange,
              onTap: () => context.push('/marks'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlassTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeesAndDocsGrid(DashboardModel dashboard) {
    final docAvailable =
        dashboard.documents.twelfthCertificate?.isNotEmpty == true;

    return Row(
      children: [
        Expanded(
          child: GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.white70,
                  size: 20,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Total Paid',
                  style: TextStyle(color: AppColors.white54, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${dashboard.fees.totalPaid.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  docAvailable
                      ? Icons.verified_rounded
                      : Icons.pending_actions_rounded,
                  color: docAvailable
                      ? AppColors.green
                      : AppColors.orange,
                  size: 20,
                ),
                const SizedBox(height: 12),
                const Text(
                  '12th Certificate',
                  style: TextStyle(color: AppColors.white54, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  docAvailable ? 'Verified' : 'Pending',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

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
            (year == now.year || (year! < 100 && year + 2000 == now.year))) {
          return record;
        }
      }
    }
    return _attendance.isNotEmpty ? _attendance.first : null;
  }

  String _formatTodayDate() {
    final now = DateTime.now();
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
    return '${now.day} ${months[now.month - 1]}';
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

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}