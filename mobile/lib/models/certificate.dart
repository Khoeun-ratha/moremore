class Certificate {
  final int id;
  final int courseId;
  final String courseTitle;
  final String certificateNumber;
  final DateTime issuedAt;

  Certificate({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.certificateNumber,
    required this.issuedAt,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) => Certificate(
    id: json['id'] as int,
    courseId: json['course_id'] as int,
    courseTitle: json['course_title'] as String,
    certificateNumber: json['certificate_number'] as String,
    issuedAt: DateTime.parse(json['issued_at'] as String),
  );
}
