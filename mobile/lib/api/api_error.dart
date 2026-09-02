import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import '../l10n/l10n_extension.dart';

/// Backend errors come back either as `{"error": "message"}` (app AppError)
/// or FastAPI's default `{"detail": ...}` (validation errors, HTTPException).
/// Those messages come from the server in English only; only the two
/// client-side fallbacks below are localized.
///
/// Always called from catch blocks — after an `await`, outside any build
/// phase — so this must use `context.trRead`, never `context.tr`
/// (`context.watch` throws when called outside build).
String extractErrorMessage(BuildContext context, Object error) {
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
      return context.trRead('couldNotReachServer');
    }
    return error.message ?? context.trRead('somethingWentWrong');
  }
  return error.toString();
}
