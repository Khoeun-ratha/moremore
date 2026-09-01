import http from './http'
import type { Course, CourseDetail, Page } from '../types/api'

export interface CourseListParams {
  q?: string
  category?: string
  page?: number
  page_size?: number
}

export interface CourseInput {
  title: string
  description: string
  category: string
  level: string
  cover_image_url?: string | null
}

export function listCourses(params: CourseListParams) {
  return http.get<Page<Course>>('/courses', { params }).then((r) => r.data)
}

export function getCourse(id: number) {
  return http.get<CourseDetail>(`/courses/${id}`).then((r) => r.data)
}

export function createCourse(input: CourseInput) {
  return http.post<Course>('/courses', input).then((r) => r.data)
}

export function updateCourse(id: number, input: Partial<CourseInput>) {
  return http.patch<Course>(`/courses/${id}`, input).then((r) => r.data)
}

export function deleteCourse(id: number) {
  return http.delete(`/courses/${id}`)
}
