import 'package:dio/dio.dart';

/// Backend errors come back either as `{"error": "message"}` (app AppError)
/// or FastAPI's default `{"detail": ...}` (validation errors, HTTPException).
String extractErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final err = data['error'];
      if (err is String) return err;
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] is String)
          return first['msg'] as String;
      }
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Could not reach the server. Check your connection and try again.';
    }
    return error.message ?? 'Something went wrong';
  }
  return error.toString();
}
