import 'package:go_router/go_router.dart';

import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../models/certificate.dart';
import '../screens/courses/course_detail_screen.dart';
import '../screens/courses/course_list_screen.dart';
import '../screens/games/game_result_screen.dart';
import '../screens/games/game_screen.dart';
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
import 'app_page_transition.dart';

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
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            buildPageWithTransition(state: state, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => buildPageWithTransition(
          state: state,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => buildPageWithTransition(
          state: state,
          child: const ForgotPasswordScreen(),
        ),
      ),
      // The four tab routes below are switched via IndexedStack inside HomeShell,
      // not pushed — they intentionally have no page transition of their own so
      // tapping a bottom-nav tab feels instant, matching standard tab-bar UX.
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
        pageBuilder: (context, state) => buildPageWithTransition(
          state: state,
          child: const EditProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/change-password',
        pageBuilder: (context, state) => buildPageWithTransition(
          state: state,
          child: const ChangePasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/certificates',
        pageBuilder: (context, state) => buildPageWithTransition(
          state: state,
          child: const MyCertificatesScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/feedback',
        pageBuilder: (context, state) => buildPageWithTransition(
          state: state,
          child: const FeedbackScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/certificates/:id',
        pageBuilder: (context, state) => buildPageWithTransition(
          state: state,
          child: CertificateDetailScreen(
            certificate: state.extra as Certificate,
          ),
        ),
      ),
      GoRoute(
        path: '/courses/:id',
        pageBuilder: (context, state) => buildPageWithTransition(
          state: state,
          child: CourseDetailScreen(
            courseId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ),
      GoRoute(
        path: '/lessons/:id',
        pageBuilder: (context, state) => buildPageWithTransition(
          state: state,
          child: LessonScreen(lessonId: int.parse(state.pathParameters['id']!)),
        ),
      ),
      GoRoute(
        path: '/lessons/:id/quiz',
        pageBuilder: (context, state) => buildPageWithTransition(
          state: state,
          child: QuizScreen(lessonId: int.parse(state.pathParameters['id']!)),
        ),
      ),
      GoRoute(
        path: '/quiz-result',
        pageBuilder: (context, state) {
          final args = state.extra as QuizResultArgs;
          return buildPageWithTransition(
            state: state,
            child: QuizResultScreen(
              result: args.result,
              courseId: args.courseId,
            ),
          );
        },
      ),
      GoRoute(
        path: '/quiz-attempts/:id',
        pageBuilder: (context, state) => buildPageWithTransition(
          state: state,
          child: QuizAttemptScreen(
            attemptId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ),
      GoRoute(
        path: '/games',
        pageBuilder: (context, state) => buildPageWithTransition(
          state: state,
          child: GameScreen(courseId: state.extra as int?),
        ),
      ),
      GoRoute(
        path: '/game-result',
        pageBuilder: (context, state) {
          final args = state.extra as GameResultArgs;
          return buildPageWithTransition(
            state: state,
            child: GameResultScreen(
              result: args.result,
              courseId: args.courseId,
            ),
          );
        },
      ),
      GoRoute(
        path: '/certificate-celebration',
        pageBuilder: (context, state) => buildPageWithTransition(
          state: state,
          child: CertificateCelebrationScreen(
            certificate: state.extra as Certificate,
          ),
        ),
      ),
    ],
    onException: (context, state, router) => router.go('/home'),
  );
}
