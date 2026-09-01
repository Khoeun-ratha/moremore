import 'package:go_router/go_router.dart';

import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../models/certificate.dart';
import '../screens/courses/course_detail_screen.dart';
import '../screens/courses/course_list_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/lessons/lesson_screen.dart';
import '../screens/profile/certificate_celebration_screen.dart';
import '../screens/profile/certificate_detail_screen.dart';
import '../screens/profile/change_password_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/feedback_screen.dart';
import '../screens/profile/my_certificates_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/quizzes/quiz_attempt_screen.dart';
import '../screens/quizzes/quiz_result_screen.dart';
import '../screens/quizzes/quiz_screen.dart';
import '../screens/shell/home_shell.dart';
import '../state/auth_store.dart';

GoRouter buildAppRouter(AuthStore authStore) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: authStore,
    redirect: (context, state) {
      const publicRoutes = {'/login', '/register', '/forgot-password'};
      final loggingIn = publicRoutes.contains(state.matchedLocation);

      if (authStore.isRestoring) {
        return null;
      }
      if (!authStore.isAuthenticated) {
        return loggingIn ? null : '/login';
      }
      if (loggingIn) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/courses',
                builder: (context, state) => const CourseListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                builder: (context, state) => const ProgressScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/profile/certificates',
        builder: (context, state) => const MyCertificatesScreen(),
      ),
      GoRoute(
        path: '/profile/feedback',
        builder: (context, state) => const FeedbackScreen(),
      ),
      GoRoute(
        path: '/profile/certificates/:id',
        builder: (context, state) =>
            CertificateDetailScreen(certificate: state.extra as Certificate),
      ),
      GoRoute(
        path: '/courses/:id',
        builder: (context, state) => CourseDetailScreen(
          courseId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/lessons/:id',
        builder: (context, state) =>
            LessonScreen(lessonId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/lessons/:id/quiz',
        builder: (context, state) =>
            QuizScreen(lessonId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/quiz-result',
        builder: (context, state) {
          final args = state.extra as QuizResultArgs;
          return QuizResultScreen(result: args.result, courseId: args.courseId);
        },
      ),
      GoRoute(
        path: '/quiz-attempts/:id',
        builder: (context, state) => QuizAttemptScreen(
          attemptId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/certificate-celebration',
        builder: (context, state) => CertificateCelebrationScreen(
          certificate: state.extra as Certificate,
        ),
      ),
    ],
    onException: (context, state, router) => router.go('/home'),
  );
}
