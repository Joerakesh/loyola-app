enum AttendanceStatus {
  present,
  absent,
  notScheduled,
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.date,
    required this.dayOrder,
    required this.week,
    required this.hours,
  });

  final String date;
  final int? dayOrder;
  final int? week;
  final List<AttendanceHour> hours;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: json['date']?.toString() ?? '',
      dayOrder: json['dayOrder'] as int?,
      week: json['week'] as int?,
      hours: (json['hours'] as List<dynamic>? ?? [])
          .map(
            (item) => AttendanceHour.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  int get presentCount =>
      hours.where((hour) => hour.status == AttendanceStatus.present).length;

  int get absentCount =>
      hours.where((hour) => hour.status == AttendanceStatus.absent).length;

  int get scheduledCount =>
      hours.where((hour) => hour.status != AttendanceStatus.notScheduled).length;

  double get percentage {
    if (scheduledCount == 0) return 0;

    return presentCount / scheduledCount * 100;
  }
}

class AttendanceHour {
  const AttendanceHour({
    required this.hour,
    required this.status,
  });

  final int hour;
  final AttendanceStatus status;

  factory AttendanceHour.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString();

    return AttendanceHour(
      hour: json['hour'] as int? ?? 0,
      status: switch (status) {
        'present' => AttendanceStatus.present,
        'absent' => AttendanceStatus.absent,
        _ => AttendanceStatus.notScheduled,
      },
    );
  }
}
