import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/auth/LoginView.vue'),
      meta: { public: true },
    },
    {
      path: '/',
      name: 'dashboard',
      component: () => import('../views/DashboardView.vue'),
      meta: { title: 'Dashboard' },
    },
    {
      path: '/courses',
      name: 'courses',
      component: () => import('../views/courses/CourseListView.vue'),
      meta: { title: 'Courses' },
    },
    {
      path: '/courses/:id',
      name: 'course-detail',
      component: () => import('../views/courses/CourseDetailView.vue'),
      props: (route) => ({ courseId: Number(route.params.id) }),
      meta: { title: 'Course details' },
    },
    {
      path: '/courses/:courseId/lessons/new',
      name: 'lesson-create',
      component: () => import('../views/lessons/LessonFormView.vue'),
      props: (route) => ({ courseId: Number(route.params.courseId) }),
      meta: { title: 'New lesson' },
    },
    {
      path: '/lessons/:id/edit',
      name: 'lesson-edit',
      component: () => import('../views/lessons/LessonFormView.vue'),
      props: (route) => ({ lessonId: Number(route.params.id) }),
      meta: { title: 'Edit lesson' },
    },
    {
      path: '/lessons/:id/quiz',
      name: 'quiz-edit',
      component: () => import('../views/quizzes/QuizFormView.vue'),
      props: (route) => ({ lessonId: Number(route.params.id) }),
      meta: { title: 'Quiz builder' },
    },
    {
      path: '/users',
      name: 'users',
      component: () => import('../views/users/UserListView.vue'),
      meta: { title: 'Users' },
    },
    {
      path: '/certificates',
      name: 'certificates',
      component: () => import('../views/certificates/CertificateListView.vue'),
      meta: { title: 'Certificates' },
    },
    {
      path: '/certificates/:id',
      name: 'certificate-detail',
      component: () => import('../views/certificates/CertificateDetailView.vue'),
      props: (route) => ({ certificateId: Number(route.params.id) }),
      meta: { title: 'Certificate detail' },
    },
    {
      path: '/users/:id/progress',
      name: 'user-progress',
      component: () => import('../views/users/UserProgressView.vue'),
      props: (route) => ({ userId: Number(route.params.id) }),
      meta: { title: 'User progress' },
    },
    {
      path: '/feedback',
      name: 'feedback',
      component: () => import('../views/feedback/FeedbackListView.vue'),
      meta: { title: 'Feedback & Suggestions' },
    },
    {
      path: '/feedback/:id',
      name: 'feedback-detail',
      component: () => import('../views/feedback/FeedbackDetailView.vue'),
      props: (route) => ({ feedbackId: Number(route.params.id) }),
      meta: { title: 'Feedback detail' },
    },
  ],
})

router.beforeEach(async (to) => {
  const auth = useAuthStore()

  if (to.meta.public) {
    return true
  }

  if (!auth.user && auth.accessToken) {
    // Page was reloaded; we have a token but haven't fetched the profile yet.
    await auth.restoreSession()
  }

  if (!auth.isAuthenticated) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }

  if (!auth.isAdmin) {
    return { name: 'login', query: { unauthorized: '1' } }
  }

  return true
})

export default router
