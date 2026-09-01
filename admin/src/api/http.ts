import axios, { type AxiosError, type InternalAxiosRequestConfig } from 'axios'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '../stores/auth'
import router from '../router'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:8000/api/v1'

const http = axios.create({ baseURL: API_BASE_URL })

http.interceptors.request.use((config) => {
  const auth = useAuthStore()
  if (auth.accessToken) {
    config.headers.Authorization = `Bearer ${auth.accessToken}`
  }
  return config
})

interface RetryableConfig extends InternalAxiosRequestConfig {
  _retry?: boolean
}

// Shared in-flight refresh promise so N parallel 401s trigger exactly one /auth/refresh call.
let refreshPromise: Promise<string> | null = null

async function forceLogoutAndRedirect() {
  const auth = useAuthStore()
  await auth.logout()
  router.push({ name: 'login', query: { redirect: router.currentRoute.value.fullPath } })
}

http.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const original = error.config as RetryableConfig | undefined

    if (error.response?.status === 403) {
      ElMessage.error('You are not authorized to do that.')
      return Promise.reject(error)
    }

    if (!original || error.response?.status !== 401 || original._retry) {
      return Promise.reject(error)
    }

    if (original.url?.includes('/auth/refresh') || original.url?.includes('/auth/login')) {
      await forceLogoutAndRedirect()
      return Promise.reject(error)
    }

    original._retry = true
    const auth = useAuthStore()

    try {
      if (!refreshPromise) {
        refreshPromise = auth.refresh().finally(() => {
          refreshPromise = null
        })
      }
      const newToken = await refreshPromise
      original.headers.Authorization = `Bearer ${newToken}`
      return http(original)
    } catch {
      await forceLogoutAndRedirect()
      return Promise.reject(error)
    }
  },
)

export default http
