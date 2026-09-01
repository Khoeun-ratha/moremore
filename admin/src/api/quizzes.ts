import http from './http'
import type { Quiz, QuizCreate, QuizWithAnswers } from '../types/api'

export function getLessonQuiz(lessonId: number) {
  return http.get<Quiz>(`/lessons/${lessonId}/quiz`).then((r) => r.data)
}

export function getQuizWithAnswers(quizId: number) {
  return http.get<QuizWithAnswers>(`/quizzes/${quizId}/full`).then((r) => r.data)
}

export function createLessonQuiz(lessonId: number, input: QuizCreate) {
  return http.post<Quiz>(`/lessons/${lessonId}/quiz`, input).then((r) => r.data)
}

export function updateQuiz(quizId: number, input: QuizCreate) {
  return http.patch<Quiz>(`/quizzes/${quizId}`, input).then((r) => r.data)
}

export function deleteQuiz(quizId: number) {
  return http.delete(`/quizzes/${quizId}`)
}
