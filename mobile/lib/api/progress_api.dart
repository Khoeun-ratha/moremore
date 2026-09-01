import 'package:dio/dio.dart';

import '../models/progress.dart';

class ProgressApi {
  ProgressApi(this._dio);
  final Dio _dio;

  Future<OverallProgress> me() async {
    final response = await _dio.get<Map<String, dynamic>>('/progress/me');
    return OverallProgress.fromJson(response.data!);
  }

  Future<CourseProgress> forCourse(int courseId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/progress/courses/$courseId',
    );
    return CourseProgress.fromJson(response.data!);
  }
}
