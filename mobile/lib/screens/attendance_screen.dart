import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../widgets/app_state_views.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_container.dart';

enum AttendanceFilter { all, thisWeek, thisMonth, lastMonth }

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
  AttendanceFilter _selectedFilter = AttendanceFilter.all;

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

  // --- FILTER LOGIC ---
  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.trim().split(RegExp(r'[-/]'));
      if (parts.length >= 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year < 100 ? year + 2000 : year, month, day);
      }
    } catch (_) {}
    return null;
  }

  List<AttendanceRecord> get _filteredRecords {
    if (_selectedFilter == AttendanceFilter.all) return _records;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _records.where((record) {
      final recordDate = _parseDate(record.date);
      if (recordDate == null) return false;

      final date = DateTime(recordDate.year, recordDate.month, recordDate.day);

      switch (_selectedFilter) {
        case AttendanceFilter.thisWeek:
          // Assuming week starts on Monday
          final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
              date.isBefore(endOfWeek.add(const Duration(days: 1)));

        case AttendanceFilter.thisMonth:
          return date.month == today.month && date.year == today.year;

        case AttendanceFilter.lastMonth:
          final lastMonthDate = DateTime(today.year, today.month - 1, 1);
          return date.month == lastMonthDate.month &&
              date.year == lastMonthDate.year;

        default:
          return true;
      }
    }).toList();
  }

  double _calculatePercentage(List<AttendanceRecord> recordsToCalculate) {
    int totalPresent = 0;
    int totalScheduled = 0;

    for (final record in recordsToCalculate) {
      totalPresent += record.presentCount;
      totalScheduled += record.scheduledCount;
    }

    if (totalScheduled == 0) return 0.0;
    return (totalPresent / totalScheduled) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final displayRecords = _filteredRecords;
    final displayPercentage = _calculatePercentage(displayRecords);
    final isGoodStanding = displayPercentage >= 75.0;

    final statusColor = isGoodStanding
        ? const Color(0xFF5ED5A8)
        : const Color(0xFFFF7A7A);

    return Scaffold(
      body: GlassBackground(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppColors.white,
          backgroundColor: Colors.black45,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: GlassAppBar(
                  title: 'Attendance',
                  showBackButton: false,
                  bottomPadding: true,
                  actions: [
                    if (!_isLoading &&
                        _error == null &&
                        displayRecords.isNotEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              '${displayPercentage.toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // --- HORIZONTAL FILTER BAR ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildFilterChip('All', AttendanceFilter.all),
                        const SizedBox(width: 10),
                        _buildFilterChip(
                          'This Week',
                          AttendanceFilter.thisWeek,
                        ),
                        const SizedBox(width: 10),
                        _buildFilterChip(
                          'This Month',
                          AttendanceFilter.thisMonth,
                        ),
                        const SizedBox(width: 10),
                        _buildFilterChip(
                          'Last Month',
                          AttendanceFilter.lastMonth,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (_isLoading)
                const SliverFillRemaining(child: LoadingView())
              else if (_error != null)
                SliverFillRemaining(
                  child: ErrorView(message: _error!, onRetry: _refreshData),
                )
              else if (_records.isEmpty)
                _buildEmptyState('No attendance records found.')
              else if (displayRecords.isEmpty)
                _buildEmptyState('No records for this period.')
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
                  sliver: SliverList.separated(
                    itemCount: displayRecords.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) =>
                        _buildAttendanceRowCard(displayRecords[index]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildFilterChip(String label, AttendanceFilter filter) {
    final isSelected = _selectedFilter == filter;
    final accentColor = const Color(0xFF9D84FF); // Theme Purple

    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = filter);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.25)
              : AppColors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.5)
                : AppColors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.white : AppColors.white54,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              size: 48,
              color: AppColors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.5),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceRowCard(AttendanceRecord record) {
    final hours = record.hours.take(5).toList();

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatDateForDisplay(record.date),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
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
          Container(
            width: 1,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppColors.white.withValues(alpha: 0.1),
          ),
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

  Widget _buildHourBadge(AttendanceHour hour) {
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'H${hour.hour}',
          style: const TextStyle(
            color: AppColors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(child: Icon(icon, color: color, size: 18)),
        ),
      ],
    );
  }

  String _formatDateForDisplay(String dateStr) {
    final parsed = _parseDate(dateStr);
    if (parsed == null) return dateStr;

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

    return '${weekdays[parsed.weekday - 1]}, ${parsed.day} ${months[parsed.month - 1]}';
  }
}
