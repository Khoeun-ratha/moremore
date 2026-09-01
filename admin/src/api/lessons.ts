import http from './http'
import type { Lesson } from '../types/api'

export interface LessonInput {
  title: string
  order_index: number
  content: string
  video_url: string | null
  file_url: string | null
}

export function listLessons(courseId: number) {
  return http.get<Lesson[]>(`/courses/${courseId}/lessons`).then((r) => r.data)
}

export function getLesson(id: number) {
  return http.get<Lesson>(`/lessons/${id}`).then((r) => r.data)
}

export function createLesson(courseId: number, input: LessonInput) {
  return http.post<Lesson>(`/courses/${courseId}/lessons`, input).then((r) => r.data)
}

export function updateLesson(id: number, input: Partial<LessonInput>) {
  return http.patch<Lesson>(`/lessons/${id}`, input).then((r) => r.data)
}

export function deleteLesson(id: number) {
  return http.delete(`/lessons/${id}`)
}
