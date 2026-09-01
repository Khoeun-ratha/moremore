import 'package:dio/dio.dart';

import '../models/course.dart';
import '../models/page.dart';
import '../models/review.dart';

class CoursesApi {
  CoursesApi(this._dio);
  final Dio _dio;

  Future<Page<Course>> list({
    String? q,
    String? category,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/courses',
      queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (category != null && category.isNotEmpty) 'category': category,
        'page': page,
        'page_size': pageSize,
      },
    );
    return Page.fromJson(response.data!, Course.fromJson);
  }

  Future<CourseDetail> get(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/courses/$id');
    return CourseDetail.fromJson(response.data!);
  }

  Future<List<Course>> recommended() async {
    final response = await _dio.get<List<dynamic>>('/courses/recommended');
    return response.data!
        .map((e) => Course.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Review>> getReviews(int courseId) async {
    final response = await _dio.get<List<dynamic>>(
      '/courses/$courseId/reviews',
    );
    return response.data!
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Review> submitReview(
    int courseId, {
    required int rating,
    String comment = '',
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/courses/$courseId/reviews/me',
      data: {'rating': rating, 'comment': comment},
    );
    return Review.fromJson(response.data!);
  }
}
