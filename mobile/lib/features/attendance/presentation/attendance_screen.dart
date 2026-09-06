import 'dart:ui';
import 'package:flutter/material.dart';

import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

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
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    try {
      final records = await widget.attendanceService.getHourlyAttendance();
      if (!mounted) return;
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
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
        ? const Color(0xFF34C759) // Green
        : const Color(0xFFFF3B30); // Red

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Attendance Records',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Dynamic Attendance Percentage Badge on top right
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
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: statusColor.withOpacity(0.5),
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
      body: Stack(
        children: [
          // Background Glow Canvas
          Positioned.fill(child: _buildBackgroundCanvas()),

          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (_error != null)
            Center(
              child: Text(_error!, style: const TextStyle(color: Colors.white)),
            )
          else
            SafeArea(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: _records.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _buildAttendanceRowCard(_records[index]),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ATTENDANCE ROW CARD (Table Format Style)
  // ---------------------------------------------------------------------------
  Widget _buildAttendanceRowCard(AttendanceRecord record) {
    final hours = record.hours.take(5).toList();

    return _GlassContainer(
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
                    color: Colors.white,
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
                    color: Colors.white54,
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
        color = const Color(0xFF34C759); // Green
        icon = Icons.check_rounded;
        break;
      case AttendanceStatus.absent:
        color = const Color(0xFFFF3B30); // Red
        icon = Icons.close_rounded;
        break;
      case AttendanceStatus.notScheduled:
        color = Colors.white24;
        icon = Icons.horizontal_rule_rounded;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'H${hour.hour}',
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.4), width: 1),
          ),
          child: Center(child: Icon(icon, color: color, size: 16)),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // BACKGROUND CANVAS
  // ---------------------------------------------------------------------------
  Widget _buildBackgroundCanvas() {
    return Container(
      color: const Color(0xFF0F0E17),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x33007AFF),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x338B0000),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// REUSABLE GLASS CONTAINER
// ---------------------------------------------------------------------------
class _GlassContainer extends StatelessWidget {
  const _GlassContainer({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final r = borderRadius ?? BorderRadius.circular(20);

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
