import 'package:dio/dio.dart';

import 'certificates_api.dart';
import 'courses_api.dart';
import 'feedback_api.dart';
import 'lessons_api.dart';
import 'progress_api.dart';
import 'quizzes_api.dart';

/// Bundles every resource API behind the one shared, authenticated [Dio].
class ApiServices {
  ApiServices(Dio dio)
    : courses = CoursesApi(dio),
      lessons = LessonsApi(dio),
      quizzes = QuizzesApi(dio),
      progress = ProgressApi(dio),
      certificates = CertificatesApi(dio),
      feedback = FeedbackApi(dio);

  final CoursesApi courses;
  final LessonsApi lessons;
  final QuizzesApi quizzes;
  final ProgressApi progress;
  final CertificatesApi certificates;
  final FeedbackApi feedback;
}
