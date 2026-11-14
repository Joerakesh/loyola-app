class StudentProfile {
  const StudentProfile({required this.fields});

  /// All profile fields returned by the Loyola LRMS API.
  final Map<String, dynamic> fields;

  String _string(String key) => fields[key]?.toString() ?? '';

  String get studentId => _string('studentId');
  String get registerNumber => _string('registerNumber');
  String get name => _string('name');
  String get mobile => _string('mobile');
  String get academicYear => _string('academicYear');
  String get program => _string('program');
  String get course => _string('course');
  String get section => _string('section');

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(fields: Map<String, dynamic>.from(json));
  }

  static const Map<String, String> labels = {
    'registerNumber': 'Register Number',
    'universityRegisterNumber': 'University Register Number',
    'studentId': 'Student ID',
    'officeId': 'Office ID',
    'name': 'Student Name',
    'nameInLocalLanguage': 'Name in Local Language',
    'tamilName': 'Tamil Name',
    'dateOfBirth': 'Date of Birth',
    'sex': 'Gender',
    'religion': 'Religion',
    'nationality': 'Nationality',
    'category': 'Category',
    'email': 'Student Email',
    'mobile': 'Mobile Number',
    'address': 'Address',
    'parentMobile': 'Parent Mobile Number',
    'parentEmail': 'Parent Email',
    'fatherName': 'Father Name',
    'motherName': 'Mother Name',
    'occupation': 'Occupation',
    'annualIncome': 'Annual Income',
    'academicYear': 'Academic Year',
    'program': 'Program',
    'course': 'Course',
    'section': 'Section',
    'hostelDayScholar': 'Hostel / Day Scholar',
    'isDetained': 'Detained Status',
    'detainedDetails': 'Detained Details',
    'district': 'District',
    'state': 'State',
    'language': 'Language',
    'createdAt': 'Profile Created',
  };

  static const List<String> displayOrder = [
    'registerNumber', 'universityRegisterNumber', 'studentId', 'officeId',
    'name', 'nameInLocalLanguage', 'tamilName', 'dateOfBirth', 'sex',
    'religion', 'nationality', 'category', 'email', 'mobile', 'address',
    'parentMobile', 'parentEmail', 'fatherName', 'motherName', 'occupation',
    'annualIncome', 'academicYear', 'program', 'course', 'section',
    'hostelDayScholar', 'isDetained', 'detainedDetails', 'district', 'state',
    'language', 'createdAt',
  ];

  String displayValue(String key) {
    final value = fields[key];
    if (value == null) return '';
    if (value is List) return value.map((item) => item.toString()).join(', ');
    if (value is Map) return value.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    if (value is bool) return value ? 'Yes' : 'No';
    return value.toString().trim();
  }
}
