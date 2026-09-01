class Lesson {
  final int id;
  final int courseId;
  final String title;
  final int orderIndex;
  final String content;
  final String? videoUrl;
  final String? fileUrl;
  final DateTime createdAt;
  final bool hasQuiz;
  final bool completed;

  Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.orderIndex,
    required this.content,
    required this.videoUrl,
    required this.fileUrl,
    required this.createdAt,
    required this.hasQuiz,
    this.completed = false,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
    id: json['id'] as int,
    courseId: json['course_id'] as int,
    title: json['title'] as String,
    orderIndex: json['order_index'] as int,
    content: json['content'] as String,
    videoUrl: json['video_url'] as String?,
    fileUrl: json['file_url'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    hasQuiz: json['has_quiz'] as bool? ?? false,
    completed: json['completed'] as bool? ?? false,
  );

  Lesson copyWith({bool? completed}) => Lesson(
    id: id,
    courseId: courseId,
    title: title,
    orderIndex: orderIndex,
    content: content,
    videoUrl: videoUrl,
    fileUrl: fileUrl,
    createdAt: createdAt,
    hasQuiz: hasQuiz,
    completed: completed ?? this.completed,
  );
}
