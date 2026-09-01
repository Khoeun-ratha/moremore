const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:8000/api/v1'
const ORIGIN = API_BASE_URL.replace(/\/api\/v1\/?$/, '')

/** Resolves a backend-relative media path (e.g. "/media/videos/x.mp4") to an absolute URL. */
export function mediaUrl(path: string | null | undefined): string {
  if (!path) return ''
  if (/^https?:\/\//.test(path)) return path
  return `${ORIGIN}${path}`
}
