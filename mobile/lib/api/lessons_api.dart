import 'package:dio/dio.dart';

import '../models/lesson.dart';
import '../models/quiz.dart';

class LessonsApi {
  LessonsApi(this._dio);
  final Dio _dio;

  Future<List<Lesson>> listForCourse(int courseId) async {
    final response = await _dio.get<List<dynamic>>(
      '/courses/$courseId/lessons',
    );
    return response.data!
        .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  Future<Lesson> get(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/lessons/$id');
    return Lesson.fromJson(response.data!);
  }

  /// Marks a quiz-less lesson complete. Lessons with a quiz can only be
  /// completed by passing that quiz (the backend rejects this call for them).
  Future<Lesson> markComplete(int id) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/lessons/$id/complete',
    );
    return Lesson.fromJson(response.data!);
  }

  Future<Quiz> getQuiz(int lessonId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/lessons/$lessonId/quiz',
    );
    return Quiz.fromJson(response.data!);
  }

  Future<List<QuizAttempt>> getAttempts(int quizId) async {
    final response = await _dio.get<List<dynamic>>('/quizzes/$quizId/attempts');
    return response.data!
        .map((e) => QuizAttempt.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
