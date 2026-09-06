class CourseMarks {
  CourseMarks({
    required this.courseCode,
    required this.courseName,
    required this.faculty,
    required this.marksAvailable,
    required this.components,
    this.totals,
  });

  final String courseCode;
  final String courseName;
  final String faculty;
  final bool marksAvailable;
  final List<MarkComponent> components;
  final MarksTotal? totals;

  factory CourseMarks.fromJson(Map<String, dynamic> json) {
    return CourseMarks(
      courseCode: json['courseCode']?.toString() ?? '',
      courseName: json['courseName']?.toString() ?? '',
      faculty: json['faculty']?.toString() ?? '',
      marksAvailable: json['marksAvailable'] as bool? ?? false,
      components: (json['components'] as List<dynamic>? ?? [])
          .map((c) => MarkComponent.fromJson(c as Map<String, dynamic>))
          .toList(),
      totals: json['totals'] != null
          ? MarksTotal.fromJson(json['totals'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MarkComponent {
  MarkComponent({required this.name, this.mark, required this.maxMark});

  final String name;
  final double? mark;
  final double maxMark;

  factory MarkComponent.fromJson(Map<String, dynamic> json) {
    final rawName = json['name']?.toString() ?? '';

    return MarkComponent(
      name: _mapComponentName(rawName), // Mapping applied here
      mark: json['mark'] != null ? (json['mark'] as num).toDouble() : null,
      maxMark: (json['maxMark'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Helper function to map names directly during JSON deserialization
  static String _mapComponentName(String rawName) {
    switch (rawName.trim()) {
      case 'Comp 1':
        return 'CIA 1';
      case 'Comp 2':
        return 'CIA 2';
      case 'Comp 3a':
        return 'Comp 1';
      case 'Comp 3b':
        return 'Comp 2';
      default:
        return rawName;
    }
  }
}

class MarksTotal {
  MarksTotal({
    required this.outOf50,
    required this.outOf100,
    this.attendance,
    this.finalMark,
  });

  final double outOf50;
  final double outOf100;
  final double? attendance;
  final double? finalMark;

  factory MarksTotal.fromJson(Map<String, dynamic> json) {
    return MarksTotal(
      outOf50: (json['outOf50'] as num?)?.toDouble() ?? 0.0,
      outOf100: (json['outOf100'] as num?)?.toDouble() ?? 0.0,
      attendance: (json['attendance'] as num?)?.toDouble(),
      finalMark: (json['final'] as num?)?.toDouble(),
    );
  }
}
