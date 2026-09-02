import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import '../l10n/l10n_extension.dart';

/// Backend errors come back either as `{"error": "message"}` (app AppError)
/// or FastAPI's default `{"detail": ...}` (validation errors, HTTPException).
/// Those messages come from the server in English only. The common auth
/// ones are mapped to translation keys below via [_knownServerErrors] so
/// they still show in the user's language; anything else falls back to the
/// server's raw (English) text.
const _knownServerErrors = <String, String>{
  'Incorrect email/phone or password': 'invalidCredentials',
  'Account is disabled': 'accountDisabled',
  'Email already registered': 'emailAlreadyRegistered',
  'Phone number already registered': 'phoneAlreadyRegistered',
  'Current password is incorrect': 'currentPasswordIncorrect',
  'This reset code is invalid or has expired': 'resetCodeInvalid',
};

/// Always called from catch blocks — after an `await`, outside any build
/// phase — so this must use `context.trRead`, never `context.tr`
/// (`context.watch` throws when called outside build).
String extractErrorMessage(BuildContext context, Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final err = data['error'];
      if (err is String) {
        final key = _knownServerErrors[err];
        return key != null ? context.trRead(key) : err;
      }
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
