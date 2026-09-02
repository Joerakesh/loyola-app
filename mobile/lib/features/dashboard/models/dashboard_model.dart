class DashboardModel {
  const DashboardModel({
    required this.student,
    required this.fees,
    required this.documents,
  });

  final StudentModel student;
  final FeesModel fees;
  final DocumentsModel documents;

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      student: StudentModel.fromJson(
        json['student'] as Map<String, dynamic>? ?? {},
      ),
      fees: FeesModel.fromJson(
        json['fees'] as Map<String, dynamic>? ?? {},
      ),
      documents: DocumentsModel.fromJson(
        json['documents'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class StudentModel {
  const StudentModel({
    required this.name,
    required this.mobile,
    required this.email,
  });

  final String name;
  final String mobile;
  final String email;

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}

class FeesModel {
  const FeesModel({
    required this.totalPaid,
  });

  final double totalPaid;

  factory FeesModel.fromJson(Map<String, dynamic> json) {
    final value = json['totalPaid'];

    return FeesModel(
      totalPaid: value is num
          ? value.toDouble()
          : double.tryParse(value?.toString() ?? '') ?? 0,
    );
  }
}

class DocumentsModel {
  const DocumentsModel({
    required this.twelfthCertificate,
  });

  final String? twelfthCertificate;

  factory DocumentsModel.fromJson(Map<String, dynamic> json) {
    return DocumentsModel(
      twelfthCertificate: json['twelfthCertificate']?.toString(),
    );
  }
}
