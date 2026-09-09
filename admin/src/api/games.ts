import http from './http'
import type { GameAttemptAdmin, LeaderboardEntry, Page } from '../types/api'

export interface GameAttemptListParams {
  q?: string
  page?: number
  page_size?: number
}

export function listGameAttempts(params: GameAttemptListParams) {
  return http.get<Page<GameAttemptAdmin>>('/games/admin/attempts', { params }).then((r) => r.data)
}

export function deleteGameAttempt(id: number) {
  return http.delete(`/games/admin/attempts/${id}`)
}

export function getLeaderboard(limit = 5) {
  return http.get<LeaderboardEntry[]>('/games/leaderboard', { params: { limit } }).then((r) => r.data)
}
