class Subject {
  const Subject({
    required this.courseCode,
    required this.title,
    required this.semester,
    required this.credits,
    required this.faculty,
  });

  final String courseCode;
  final String title;
  final int semester;
  final int credits;
  final String faculty;

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      courseCode: json['course_code']?.toString() ?? '',
      title: json['course_title']?.toString() ?? '',
      semester: (json['semester'] as num?)?.toInt() ?? 0,
      credits: (json['credits'] as num?)?.toInt() ?? 0,
      faculty: json['faculty']?.toString() ?? '',
    );
  }
}