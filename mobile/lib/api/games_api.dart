import 'package:dio/dio.dart';

import '../models/game.dart';
import '../models/page.dart';

class GamesApi {
  GamesApi(this._dio);
  final Dio _dio;

  Future<List<GameQuestion>> randomQuiz({int? courseId, int count = 20}) async {
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

  Future<List<LeaderboardEntry>> leaderboard({int limit = 20}) async {
    final response = await _dio.get<List<dynamic>>(
      '/games/leaderboard',
      queryParameters: {'limit': limit},
    );
    return response.data!
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Page<AdminGameAttempt>> adminListAttempts({
    String? q,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/games/admin/attempts',
      queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        'page': page,
        'page_size': pageSize,
      },
    );
    return Page.fromJson(response.data!, AdminGameAttempt.fromJson);
  }

  Future<void> adminDeleteAttempt(int attemptId) async {
    await _dio.delete<void>('/games/admin/attempts/$attemptId');
  }
}
