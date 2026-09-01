class Review {
  final int id;
  final int courseId;
  final int userId;
  final String reviewerName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.courseId,
    required this.userId,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: json['id'] as int,
    courseId: json['course_id'] as int,
    userId: json['user_id'] as int,
    reviewerName: json['reviewer_name'] as String,
    rating: json['rating'] as int,
    comment: json['comment'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
