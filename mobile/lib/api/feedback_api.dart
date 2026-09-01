import 'package:dio/dio.dart';

import '../models/feedback.dart';

class FeedbackApi {
  FeedbackApi(this._dio);
  final Dio _dio;

  Future<FeedbackItem> submit({
    required FeedbackType type,
    required String subject,
    required String message,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/feedback',
      data: {
        'type': feedbackTypeToJson(type),
        'subject': subject,
        'message': message,
      },
    );
    return FeedbackItem.fromJson(response.data!);
  }

  Future<List<FeedbackItem>> mine() async {
    final response = await _dio.get<List<dynamic>>('/feedback/me');
    return response.data!
        .map((e) => FeedbackItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
