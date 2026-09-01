import 'package:dio/dio.dart';

import '../models/quiz.dart';

class QuizzesApi {
  QuizzesApi(this._dio);
  final Dio _dio;

  Future<QuizResult> submit(int quizId, Map<int, int> answers) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/quizzes/$quizId/submit',
      data: {
        'answers': answers.entries
            .map((e) => {'question_id': e.key, 'choice_id': e.value})
            .toList(),
      },
    );
    return QuizResult.fromJson(response.data!);
  }

  Future<QuizResult> getAttemptDetail(int attemptId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/quizzes/attempts/$attemptId',
    );
    return QuizResult.fromJson(response.data!);
  }
}
