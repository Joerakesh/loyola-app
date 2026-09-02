import 'package:flutter/material.dart';

import '../../attendance/models/attendance_model.dart';
import '../../attendance/presentation/current_week_attendance_card.dart';
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

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        widget.dashboardService.getDashboard(),
        widget.attendanceService.getHourlyAttendance(),
      ]);

      final dashboard = results[0] as DashboardModel;

      final attendance = results[1] as List<AttendanceRecord>;

      if (!mounted) return;

      setState(() {
        _dashboard = dashboard;
        _attendance = attendance;
        _isLoading = false;
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loyola ERP')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56),

                const SizedBox(height: 16),

                const Text(
                  'Unable to load dashboard',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Text(_error!, textAlign: TextAlign.center),

                const SizedBox(height: 24),

                FilledButton.icon(
                  onPressed: _loadDashboard,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final dashboard = _dashboard!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyola ERP'),
        actions: [
          IconButton(
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadDashboard,

        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.all(20),

          children: [
            Text(
              _greeting(),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            Text(
              'Welcome back 👋',
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            const SizedBox(height: 24),

            // Student information
            _buildStudentCard(dashboard.student),

            const SizedBox(height: 20),

            // Current week attendance
            CurrentWeekAttendanceCard(records: _attendance),

            const SizedBox(height: 20),

            // Feature cards
            Row(
              children: [
                Expanded(
                  child: _buildFeatureCard(
                    icon: Icons.calendar_month_outlined,
                    title: 'Attendance',
                    subtitle: 'View attendance',
                    onTap: () {},
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _buildFeatureCard(
                    icon: Icons.menu_book_outlined,
                    title: 'Subjects',
                    subtitle: 'View subjects',
                    onTap: () {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildFeatureCard(
                    icon: Icons.assignment_outlined,
                    title: 'Marks',
                    subtitle: 'Internal marks',
                    onTap: () {},
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _buildFeatureCard(
                    icon: Icons.payments_outlined,
                    title: 'Fees',
                    subtitle:
                        '₹${dashboard.fees.totalPaid.toStringAsFixed(0)} paid',
                    onTap: () {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Documents
            Text(
              'Documents',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.description_outlined),
                ),

                title: const Text('12th Certificate'),

                subtitle: Text(
                  dashboard.documents.twelfthCertificate?.isNotEmpty == true
                      ? 'Available'
                      : 'Not available',
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(StudentModel student) {
    return Card(
      elevation: 0,

      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const CircleAvatar(radius: 28, child: Icon(Icons.person, size: 30)),

            const SizedBox(height: 16),

            Text(
              student.name.isEmpty ? 'Student' : student.name,

              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            if (student.email.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(student.email),
            ],

            if (student.mobile.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(student.mobile),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,

      child: InkWell(
        borderRadius: BorderRadius.circular(12),

        onTap: onTap,

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Icon(icon, size: 30),

              const SizedBox(height: 16),

              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 4),

              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }
}
