import 'dart:ui';
import 'package:flutter/material.dart';

import '../../attendance/models/attendance_model.dart';
import '../../attendance/services/attendance_service.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';

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
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
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

  Future<void> _loadDashboard() async {
    try {
      final results = await Future.wait([
        widget.dashboardService.getDashboard(),
        widget.attendanceService.getHourlyAttendance(),
        widget.attendanceService.getAttendanceSummary(),
      ]);

      if (!mounted) return;

      setState(() {
        _dashboard = results[0] as DashboardModel;
        _attendance = results[1] as List<AttendanceRecord>;
        _attendanceSummary = results[2];
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildGlassLoadingScreen();
    if (_error != null || _dashboard == null) return _buildGlassErrorScreen();

    final dashboard = _dashboard!;
    final todayRecord = _getTodayAttendance();

    return Scaffold(
      extendBody: true, // Allows content to scroll underneath floating navbar
      body: Stack(
        children: [
          // Background Gradient Glows (Creates the iOS Liquid Effect)
          Positioned.fill(child: _buildBackgroundCanvas()),

          // Main Scrollable Body
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _loadDashboard,
              color: Colors.white,
              backgroundColor: Colors.black45,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(dashboard)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
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
          ),

          // Floating Glass Floating Navbar
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: _buildFloatingGlassNavbar(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BACKGROUND CANVAS
  // ---------------------------------------------------------------------------

  Widget _buildBackgroundCanvas() {
    return Container(
      color: const Color(0xFF0F0E17), // Deep dark base
      child: Stack(
        children: [
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x668B0000), // Crimson glow
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x444A154B), // Subtle purple glow
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader(DashboardModel dashboard) {
    final student = dashboard.student;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting().toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white54,
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
                    color: Colors.white,
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
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _GlassAvatar(name: student.name),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TODAY'S ATTENDANCE & DAY ORDER
  // ---------------------------------------------------------------------------

  Widget _buildTodayCard(AttendanceRecord? record) {
    final dayOrder = record?.dayOrder ?? 0;
    final hours = record?.hours.take(5).toList() ?? [];

    final percentage = _getAttendancePercentage();

    return _GlassContainer(
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
                          color: const Color(0xFF8B0000).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          dayOrder > 0 ? 'DAY ORDER $dayOrder' : 'NO DAY ORDER',
                          style: const TextStyle(
                            color: Colors.white,
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
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Today's Attendance",
                    style: TextStyle(
                      color: Colors.white,
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
                  style: TextStyle(color: Colors.white54),
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
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Text(
        '${percentage.toStringAsFixed(2)}%',
        style: const TextStyle(
          color: Colors.white,
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
        color = const Color(0xFF34C759);
        icon = Icons.check_rounded;
        break;
      case AttendanceStatus.absent:
        color = const Color(0xFFFF3B30);
        icon = Icons.close_rounded;
        break;
      case AttendanceStatus.notScheduled:
        color = Colors.white30;
        icon = Icons.horizontal_rule_rounded;
        break;
    }

    return Column(
      children: [
        Text(
          'H${hour.hour}',
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Center(child: Icon(icon, color: color, size: 18)),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // QUICK ACCESS GRID
  // ---------------------------------------------------------------------------

  Widget _buildQuickAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
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
              icon: Icons.calendar_month_rounded,
              title: 'Attendance',
              subtitle: 'View history',
              color: const Color(0xFF007AFF),
              onTap: () {
                Navigator.pushNamed(context, '/attendance');
              },
            ),
            _buildGlassTile(
              icon: Icons.menu_book_rounded,
              title: 'Subjects',
              subtitle: 'Course list',
              color: const Color(0xFFAF52DE),
              onTap: () {},
            ),
            _buildGlassTile(
              icon: Icons.assessment_rounded,
              title: 'Marks',
              subtitle: 'CIA breakdown',
              color: const Color(0xFFFF9500),
              onTap: () {
                Navigator.pushNamed(context, '/marks');
              },
            ),
            _buildGlassTile(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Fees',
              subtitle: 'Payment records',
              color: const Color(0xFF34C759),
              onTap: () {},
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
    return _GlassContainer(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
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
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUMMARY CARDS (FEES & DOCUMENTS)
  // ---------------------------------------------------------------------------

  Widget _buildFeesAndDocsGrid(DashboardModel dashboard) {
    final docAvailable =
        dashboard.documents.twelfthCertificate?.isNotEmpty == true;

    return Row(
      children: [
        Expanded(
          child: _GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Total Paid',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${dashboard.fees.totalPaid.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
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
          child: _GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  docAvailable
                      ? Icons.verified_rounded
                      : Icons.pending_actions_rounded,
                  color: docAvailable
                      ? const Color(0xFF34C759)
                      : const Color(0xFFFF9500),
                  size: 20,
                ),
                const SizedBox(height: 12),
                const Text(
                  '12th Certificate',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  docAvailable ? 'Verified' : 'Pending',
                  style: const TextStyle(
                    color: Colors.white,
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

  // ---------------------------------------------------------------------------
  // FLOATING GLASS NAVBAR
  // ---------------------------------------------------------------------------

  Widget _buildFloatingGlassNavbar() {
    return _GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.grid_view_rounded, 'Home'),
          _buildNavItem(1, Icons.calendar_today_rounded, 'Attendance'),
          _buildNavItem(2, Icons.book_rounded, 'Subjects'),
          _buildNavItem(3, Icons.person_rounded, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedNavIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedNavIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white38,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS & SCREENS
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

  Widget _buildGlassLoadingScreen() {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackgroundCanvas()),
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildGlassErrorScreen() {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackgroundCanvas()),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, color: Colors.white54, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Failed to fetch dashboard',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadDashboard,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// REUSABLE GLASS COMPONENTS
// ---------------------------------------------------------------------------

class _GlassContainer extends StatelessWidget {
  const _GlassContainer({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final r = borderRadius ?? BorderRadius.circular(24);

    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: r,
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassAvatar extends StatelessWidget {
  const _GlassAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
