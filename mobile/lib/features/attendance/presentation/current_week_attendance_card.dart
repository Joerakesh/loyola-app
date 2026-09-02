import 'package:flutter/material.dart';

import '../models/attendance_model.dart';

class CurrentWeekAttendanceCard extends StatelessWidget {
  const CurrentWeekAttendanceCard({super.key, required this.records});

  final List<AttendanceRecord> records;

  @override
  Widget build(BuildContext context) {
    final currentWeek = _latestWeek(records);

    final recordsToShow = records
        .where((record) => record.week == currentWeek)
        .toList();

    final totalPresent = recordsToShow.fold<int>(
      0,
      (sum, record) => sum + record.presentCount,
    );

    final totalAbsent = recordsToShow.fold<int>(
      0,
      (sum, record) => sum + record.absentCount,
    );

    final totalScheduled = recordsToShow.fold<int>(
      0,
      (sum, record) => sum + record.scheduledCount,
    );

    final percentage = totalScheduled == 0
        ? 0.0
        : totalPresent / totalScheduled * 100;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Current Week Attendance',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (recordsToShow.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No attendance data available'),
                ),
              )
            else ...[
              _buildDays(context, recordsToShow),

              const SizedBox(height: 20),

              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 8,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  _buildLegend(
                    context,
                    Icons.check_circle,
                    'Present',
                    totalPresent,
                  ),
                  const SizedBox(width: 20),
                  _buildLegend(context, Icons.cancel, 'Absent', totalAbsent),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDays(BuildContext context, List<AttendanceRecord> records) {
    return Row(
      children: records.map((record) {
        final status = _dayStatus(record);

        return Expanded(
          child: Column(
            children: [
              Text(
                _dayName(record.date),
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _statusColor(context, status).withOpacity(0.12),
                ),
                child: Icon(
                  _statusIcon(status),
                  color: _statusColor(context, status),
                  size: 22,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                '${record.percentage.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegend(
    BuildContext context,
    IconData icon,
    String label,
    int count,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text('$label $count'),
      ],
    );
  }

  AttendanceStatus _dayStatus(AttendanceRecord record) {
    if (record.absentCount > 0) {
      return AttendanceStatus.absent;
    }

    if (record.presentCount > 0) {
      return AttendanceStatus.present;
    }

    return AttendanceStatus.notScheduled;
  }

  IconData _statusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check;

      case AttendanceStatus.absent:
        return Icons.close;

      case AttendanceStatus.notScheduled:
        return Icons.remove;
    }
  }

  Color _statusColor(BuildContext context, AttendanceStatus status) {
    final scheme = Theme.of(context).colorScheme;

    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;

      case AttendanceStatus.absent:
        return scheme.error;

      case AttendanceStatus.notScheduled:
        return scheme.outline;
    }
  }

  String _dayName(String date) {
    try {
      final parts = date.split(RegExp(r'[-/]'));

      if (parts.length >= 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);

        if (day != null && month != null) {
          final actualYear = year != null && year > 1000
              ? year
              : DateTime.now().year;

          final parsed = DateTime(actualYear, month, day);

          return _weekday(parsed);
        }
      }
    } catch (_) {}

    return date.length >= 3 ? date.substring(0, 3) : date;
  }

  String _weekday(DateTime date) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return names[date.weekday - 1];
  }

  int? _latestWeek(List<AttendanceRecord> records) {
    final weeks = records
        .map((record) => record.week)
        .whereType<int>()
        .toList();

    if (weeks.isEmpty) {
      return null;
    }

    weeks.sort();

    return weeks.last;
  }
}
