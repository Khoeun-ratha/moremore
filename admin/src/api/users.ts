import http from './http'
import type { OverallProgress, User } from '../types/api'

export function listUsers() {
  return http.get<User[]>('/users').then((r) => r.data)
}

export function getUser(id: number) {
  return http.get<User>(`/users/${id}`).then((r) => r.data)
}

export function updateUser(id: number, input: Partial<Pick<User, 'full_name' | 'is_active' | 'role'>>) {
  return http.patch<User>(`/users/${id}`, input).then((r) => r.data)
}

export function deleteUser(id: number) {
  return http.delete(`/users/${id}`)
}

export function getUserProgress(id: number) {
  return http.get<OverallProgress>(`/users/${id}/progress`).then((r) => r.data)
}
