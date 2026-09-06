import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../widgets/app_state_views.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_container.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key, required this.attendanceService});
  final AttendanceService attendanceService;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<AttendanceRecord> _records = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCached();
    _refreshData();
  }

  Future<void> _loadCached() async {
    try {
      final cached = await widget.attendanceService.getCachedHourlyAttendance();
      if (!mounted || cached == null) return;
      setState(() {
        _records = cached;
        _isLoading = false;
        _error = null;
      });
    } catch (_) {}
  }

  Future<void> _refreshData() async {
    try {
      final result = await widget.attendanceService.fetchHourlyAttendance();
      if (!mounted) return;
      setState(() {
        if (result.changed) _records = result.data;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_records.isEmpty) {
          _error = e.toString();
          _isLoading = false;
        }
      });
    }
  }

  // Calculate overall cumulative attendance percentage
  double _calculateOverallPercentage() {
    int totalPresent = 0;
    int totalScheduled = 0;

    for (final record in _records) {
      totalPresent += record.presentCount;
      totalScheduled += record.scheduledCount;
    }

    if (totalScheduled == 0) return 0.0;
    return (totalPresent / totalScheduled) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final overallPercentage = _calculateOverallPercentage();
    final isGoodStanding = overallPercentage >= 80.0;

    // Dynamic color coding based on 80% threshold
    final statusColor = isGoodStanding
        ? AppColors.green
        : AppColors.red;

    return Scaffold(
      body: GlassBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: GlassAppBar(
                title: 'Attendance Records',
                showBackButton: false,
                bottomPadding: true,
                actions: [
                  if (!_isLoading && _error == null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.5),
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            '${overallPercentage.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(child: LoadingView())
            else if (_error != null)
              SliverFillRemaining(
                child: ErrorView(
                  message: _error!,
                  onRetry: _refreshData,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
                sliver: SliverList.separated(
                  itemCount: _records.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _buildAttendanceRowCard(_records[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ATTENDANCE ROW CARD (Table Format Style)
  // ---------------------------------------------------------------------------
  Widget _buildAttendanceRowCard(AttendanceRecord record) {
    final hours = record.hours.take(5).toList();

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Side: Date and Day Order inside brackets
          SizedBox(
            width: 95,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  record.date,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.dayOrder != null && record.dayOrder! > 0
                      ? '(Day Order ${record.dayOrder})'
                      : '(No Day)',
                  style: const TextStyle(
                    color: AppColors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),
          const VerticalDivider(color: Colors.white24, thickness: 1),
          const SizedBox(width: 8),

          // Right Side: 5 Hours Table Cells
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: hours.map((hour) => _buildHourBadge(hour)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HOUR STATUS BADGE CELL
  // ---------------------------------------------------------------------------
  Widget _buildHourBadge(AttendanceHour hour) {
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
        color = AppColors.white24;
        icon = Icons.horizontal_rule_rounded;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'H${hour.hour}',
          style: const TextStyle(
            color: AppColors.white60,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
          ),
          child: Center(child: Icon(icon, color: color, size: 16)),
        ),
      ],
    );
  }
}