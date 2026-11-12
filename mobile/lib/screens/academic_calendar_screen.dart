import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../services/college_updates_service.dart';

class AcademicCalendarScreen extends StatefulWidget {
  const AcademicCalendarScreen({super.key, required this.service});

  final CollegeUpdatesService service;

  @override
  State<AcademicCalendarScreen> createState() => _AcademicCalendarScreenState();
}

class _AcademicCalendarScreenState extends State<AcademicCalendarScreen> {
  Map<String, dynamic>? _calendar;
  bool _loading = true;
  String? _error;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDate;

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final updates = await widget.service.fetchUpdates(refresh: refresh);
      final rawCalendar = updates['calendar'];
      final calendar = rawCalendar is Map
          ? rawCalendar.cast<String, dynamic>()
          : <String, dynamic>{};
      final month = _parseMonth(calendar['month']?.toString());
      final entries = _items(calendar['entries']);
      final entryDates = entries
          .map((entry) => _dateForEntry(entry['dateLabel']?.toString() ?? '', month))
          .whereType<DateTime>()
          .where((date) => date.year == month.year && date.month == month.month)
          .toList();
      final today = DateUtils.dateOnly(DateTime.now());
      final selectedDate = entryDates.isNotEmpty
          ? entryDates.first
          : today.year == month.year && today.month == month.month
          ? today
          : DateTime(month.year, month.month, 1);

      if (!mounted) return;
      setState(() {
        _calendar = calendar;
        _month = month;
        _selectedDate = selectedDate;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _items(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((item) => item.cast<String, dynamic>()).toList();
  }

  DateTime _parseMonth(String? value) {
    final match = RegExp(r'^\s*([A-Za-z]+)\s+(\d{4})\s*$').firstMatch(value ?? '');
    if (match != null) {
      final monthIndex = _monthNames.indexWhere(
        (name) => name.toLowerCase() == match.group(1)!.toLowerCase(),
      );
      final year = int.tryParse(match.group(2)!);
      if (monthIndex >= 0 && year != null) return DateTime(year, monthIndex + 1);
    }
    return DateTime(DateTime.now().year, DateTime.now().month);
  }

  DateTime? _dateForEntry(String label, DateTime month) {
    final value = label.trim();
    final isoDate = DateTime.tryParse(value);
    if (isoDate != null) return DateUtils.dateOnly(isoDate);

    final numeric = RegExp(
      r'\b(\d{1,2})[./-](\d{1,2})(?:[./-](\d{2,4}))?\b',
    ).firstMatch(value);
    if (numeric != null) {
      final first = int.parse(numeric.group(1)!);
      final second = int.parse(numeric.group(2)!);
      final day = first > 12 ? first : second > 12 ? second : first;
      final monthNumber = first > 12 ? second : second > 12 ? first : second;
      final year = int.tryParse(numeric.group(3) ?? '') ?? month.year;
      return _validDate(year, monthNumber, day);
    }

    final namedMonth = RegExp(
      r'(?:(\d{1,2})(?:st|nd|rd|th)?\s+([A-Za-z]+)|([A-Za-z]+)\s+(\d{1,2})(?:st|nd|rd|th)?)',
      caseSensitive: false,
    ).firstMatch(value);
    if (namedMonth != null) {
      final day = int.tryParse(namedMonth.group(1) ?? namedMonth.group(4) ?? '');
      final name = namedMonth.group(2) ?? namedMonth.group(3) ?? '';
      final monthIndex = _monthNames.indexWhere(
        (monthName) =>
            monthName.toLowerCase().startsWith(name.toLowerCase()),
      );
      if (day != null && monthIndex >= 0) {
        return _validDate(month.year, monthIndex + 1, day);
      }
    }

    final dayOnly = RegExp(r'^\s*(\d{1,2})(?:st|nd|rd|th)?\s*$')
        .firstMatch(value);
    if (dayOnly != null) {
      return _validDate(month.year, month.month, int.parse(dayOnly.group(1)!));
    }

    return null;
  }

  DateTime? _validDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1) return null;
    final date = DateTime(year, month, day);
    return date.month == month ? date : null;
  }

  Map<int, List<Map<String, dynamic>>> get _entriesByDay {
    final calendar = _calendar;
    if (calendar == null) return const {};
    final result = <int, List<Map<String, dynamic>>>{};
    for (final entry in _items(calendar['entries'])) {
      final date = _dateForEntry(entry['dateLabel']?.toString() ?? '', _month);
      if (date == null || date.year != _month.year || date.month != _month.month) {
        continue;
      }
      (result[date.day] ??= []).add(entry);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Academic calendar',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh calendar',
            onPressed: _loading ? null : () => _load(refresh: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _loading && _calendar == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _calendar == null
          ? _errorView()
          : RefreshIndicator(
              onRefresh: () => _load(refresh: true),
              color: AppColors.crimson,
              backgroundColor: AppColors.backgroundSoft,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
                children: [
                  _monthHeader(),
                  const SizedBox(height: 18),
                  _calendarGrid(),
                  const SizedBox(height: 24),
                  _selectedDayDetails(),
                  if (_calendar?['sourceUrl'] != null) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Dates provided by Loyola College',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.white38, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _monthHeader() {
    final monthLabel = '${_monthNames[_month.month - 1]} ${_month.year}';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Academic schedule',
                style: TextStyle(color: AppColors.white54, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                monthLabel,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.crimson.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_entriesByDay.length} scheduled days',
            style: const TextStyle(
              color: AppColors.crimson,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _calendarGrid() {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingDays = DateTime(_month.year, _month.month, 1).weekday % 7;
    final cellCount = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;
    final entries = _entriesByDay;
    final today = DateUtils.dateOnly(DateTime.now());

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final weekday in _weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      weekday,
                      style: const TextStyle(
                        color: AppColors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cellCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (context, index) {
              final day = index - leadingDays + 1;
              if (day < 1 || day > daysInMonth) return const SizedBox.shrink();

              final date = DateTime(_month.year, _month.month, day);
              final selected = _selectedDate != null &&
                  DateUtils.isSameDay(date, _selectedDate);
              final isToday = DateUtils.isSameDay(date, today);
              final hasEntries = entries.containsKey(day);

              return InkWell(
                onTap: () => setState(() => _selectedDate = date),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.crimson
                        : AppColors.white.withValues(alpha: 0.025),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isToday && !selected
                          ? AppColors.crimson.withValues(alpha: 0.55)
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          color: selected ? AppColors.background : AppColors.white,
                          fontSize: 13,
                          fontWeight: selected || isToday
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasEntries
                              ? selected
                                    ? AppColors.background
                                    : AppColors.crimson
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.circle, size: 7, color: AppColors.crimson),
              SizedBox(width: 6),
              Text(
                'Academic item scheduled',
                style: TextStyle(color: AppColors.white54, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _selectedDayDetails() {
    final date = _selectedDate;
    if (date == null) return const SizedBox.shrink();
    final entries = _entriesByDay[date.day] ?? const [];
    final dateLabel = '${_monthNames[date.month - 1]} ${date.day}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateLabel,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 11),
        if (entries.isEmpty)
          _detailCard(
            icon: Icons.event_available_rounded,
            title: 'No scheduled item',
            subtitle: 'There are no academic calendar entries for this date.',
          )
        else
          ...entries.map((entry) {
            final event = entry['event']?.toString().trim() ?? '';
            final dayOrder = entry['dayOrder']?.toString().trim() ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _detailCard(
                icon: Icons.event_note_rounded,
                title: event.isEmpty || event == '—' ? 'Scheduled college day' : event,
                subtitle: dayOrder,
              ),
            );
          }),
      ],
    );
  }

  Widget _detailCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.backgroundSoft,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.crimson.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.crimson, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.crimson,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 38, color: AppColors.white54),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unable to load the academic calendar.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.white70, fontSize: 13),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => _load(refresh: true),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
