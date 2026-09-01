class Course {
  final int id;
  final String title;
  final String description;
  final String category;
  final String level;
  final String? coverImageUrl;
  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? averageRating;
  final int reviewCount;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.level,
    required this.coverImageUrl,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.averageRating,
    this.reviewCount = 0,
  });

  factory Course.fromJson(Map<String, dynamic> json) => Course(
    id: json['id'] as int,
    title: json['title'] as String,
    description: json['description'] as String,
    category: json['category'] as String,
    level: json['level'] as String,
    coverImageUrl: json['cover_image_url'] as String?,
    createdBy: json['created_by'] as int,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    averageRating: (json['average_rating'] as num?)?.toDouble(),
    reviewCount: json['review_count'] as int? ?? 0,
  );
}

class CourseDetail extends Course {
  final int lessonCount;

  CourseDetail({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.level,
    required super.coverImageUrl,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    super.averageRating,
    super.reviewCount = 0,
    required this.lessonCount,
  });

  factory CourseDetail.fromJson(Map<String, dynamic> json) => CourseDetail(
    id: json['id'] as int,
    title: json['title'] as String,
    description: json['description'] as String,
    category: json['category'] as String,
    level: json['level'] as String,
    coverImageUrl: json['cover_image_url'] as String?,
    createdBy: json['created_by'] as int,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    averageRating: (json['average_rating'] as num?)?.toDouble(),
    reviewCount: json['review_count'] as int? ?? 0,
    lessonCount: json['lesson_count'] as int,
  );
}
