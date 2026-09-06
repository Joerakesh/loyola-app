class StudentProfile {
  const StudentProfile({
    required this.studentId,
    required this.registerNumber,
    required this.name,
    required this.mobile,
    required this.academicYear,
    required this.program,
    required this.course,
    required this.section,
  });

  final String studentId;
  final String registerNumber;
  final String name;
  final String mobile;
  final String academicYear;
  final String program;
  final String course;
  final String section;

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      studentId: json['studentId']?.toString() ?? '',
      registerNumber: json['registerNumber']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      academicYear: json['academicYear']?.toString() ?? '',
      program: json['program']?.toString() ?? '',
      course: json['course']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
    );
  }
}