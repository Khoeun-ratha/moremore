import { AxiosError } from 'axios'

/**
 * Backend errors come back either as `{"error": "message"}` (app AppError)
 * or FastAPI's default `{"detail": ...}` (validation errors, HTTPException).
 * Mirrors mobile/lib/api/api_error.dart's extractErrorMessage so admin
 * Create/Edit flows surface the real reason instead of a static string.
 */
export function extractErrorMessage(error: unknown, fallback: string): string {
  if (error instanceof AxiosError) {
    const data = error.response?.data
    if (data && typeof data === 'object') {
      const err = (data as Record<string, unknown>).error
      if (typeof err === 'string') return err

      const detail = (data as Record<string, unknown>).detail
      if (typeof detail === 'string') return detail
      if (Array.isArray(detail) && detail.length > 0) {
        const first = detail[0]
        if (first && typeof first === 'object' && typeof (first as Record<string, unknown>).msg === 'string') {
          return (first as Record<string, unknown>).msg as string
        }
      }
    }
    if (error.code === 'ECONNABORTED' || error.message === 'Network Error') {
      return 'Could not reach the server. Check your connection and try again.'
    }
  }
  return fallback
}
