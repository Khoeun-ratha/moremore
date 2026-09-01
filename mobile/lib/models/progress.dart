class CourseProgress {
  final int courseId;
  final String courseTitle;
  final int totalLessons;
  final int completedLessons;
  final double percentage;

  CourseProgress({
    required this.courseId,
    required this.courseTitle,
    required this.totalLessons,
    required this.completedLessons,
    required this.percentage,
  });

  factory CourseProgress.fromJson(Map<String, dynamic> json) => CourseProgress(
    courseId: json['course_id'] as int,
    courseTitle: json['course_title'] as String,
    totalLessons: json['total_lessons'] as int,
    completedLessons: json['completed_lessons'] as int,
    percentage: (json['percentage'] as num).toDouble(),
  );
}

class OverallProgress {
  final List<CourseProgress> courses;
  final double overallPercentage;

  OverallProgress({required this.courses, required this.overallPercentage});

  factory OverallProgress.fromJson(Map<String, dynamic> json) =>
      OverallProgress(
        courses: (json['courses'] as List)
            .map((e) => CourseProgress.fromJson(e as Map<String, dynamic>))
            .toList(),
        overallPercentage: (json['overall_percentage'] as num).toDouble(),
      );
}
