import 'package:dio/dio.dart';

import '../models/game.dart';

class GamesApi {
  GamesApi(this._dio);
  final Dio _dio;

  Future<List<GameQuestion>> randomQuiz({int? courseId, int count = 10}) async {
    final response = await _dio.get<List<dynamic>>(
      '/games/random-quiz',
      queryParameters: {
        if (courseId != null) 'course_id': courseId,
        'count': count,
      },
    );
    return response.data!
        .map((e) => GameQuestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GameResult> submit(Map<int, int> answers, {int? courseId}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/games/random-quiz/submit',
      queryParameters: {if (courseId != null) 'course_id': courseId},
      data: {
        'answers': answers.entries
            .map((e) => {'question_id': e.key, 'choice_id': e.value})
            .toList(),
      },
    );
    return GameResult.fromJson(response.data!);
  }

  Future<List<GameAttempt>> myAttempts() async {
    final response = await _dio.get<List<dynamic>>('/games/my-attempts');
    return response.data!
        .map((e) => GameAttempt.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
