import http from './http'
import type { Feedback, FeedbackStatus, FeedbackType, Page } from '../types/api'

export interface FeedbackListParams {
  q?: string
  type?: FeedbackType
  status?: FeedbackStatus
  page?: number
  page_size?: number
}

export function listFeedback(params: FeedbackListParams) {
  return http.get<Page<Feedback>>('/feedback', { params }).then((r) => r.data)
}

export function getFeedback(id: number) {
  return http.get<Feedback>(`/feedback/${id}`).then((r) => r.data)
}

export function updateFeedbackStatus(id: number, status: FeedbackStatus) {
  return http.patch<Feedback>(`/feedback/${id}`, { status }).then((r) => r.data)
}
