import { defineStore } from 'pinia'
import axios from 'axios'
import type { TokenPair, User } from '../types/api'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:8000/api/v1'

// Bare axios instance with no interceptors — used only for login/register/refresh so those
// calls can never recurse into the main client's 401-refresh interceptor.
const bare = axios.create({ baseURL: API_BASE_URL })

const STORAGE_KEY = 'admin_auth'

interface StoredAuth {
  accessToken: string
  refreshToken: string
}

function loadStored(): StoredAuth | null {
  const raw = localStorage.getItem(STORAGE_KEY)
  if (!raw) return null
  try {
    return JSON.parse(raw) as StoredAuth
  } catch {
    return null
  }
}

export const useAuthStore = defineStore('auth', {
  state: () => ({
    accessToken: loadStored()?.accessToken ?? null as string | null,
    refreshToken: loadStored()?.refreshToken ?? null as string | null,
    user: null as User | null,
  }),

  getters: {
    isAuthenticated: (state) => !!state.accessToken && !!state.user,
    isAdmin: (state) => state.user?.role === 'admin',
  },

  actions: {
    persist() {
      if (this.accessToken && this.refreshToken) {
        localStorage.setItem(
          STORAGE_KEY,
          JSON.stringify({ accessToken: this.accessToken, refreshToken: this.refreshToken }),
        )
      } else {
        localStorage.removeItem(STORAGE_KEY)
      }
    },

    async login(email: string, password: string) {
      const form = new URLSearchParams()
      form.set('username', email)
      form.set('password', password)
      const { data } = await bare.post<TokenPair>('/auth/login', form, {
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      })
      this.accessToken = data.access_token
      this.refreshToken = data.refresh_token
      this.persist()
      await this.fetchCurrentUser()
    },

    async fetchCurrentUser() {
      const { data } = await bare.get<User>('/auth/me', {
        headers: { Authorization: `Bearer ${this.accessToken}` },
      })
      this.user = data
    },

    /** Called by the API client's 401 interceptor. Returns the new access token. */
    async refresh(): Promise<string> {
      if (!this.refreshToken) throw new Error('No refresh token available')
      const { data } = await bare.post<TokenPair>('/auth/refresh', {
        refresh_token: this.refreshToken,
      })
      this.accessToken = data.access_token
      this.refreshToken = data.refresh_token
      this.persist()
      return data.access_token
    },

    async logout() {
      const token = this.refreshToken
      this.accessToken = null
      this.refreshToken = null
      this.user = null
      this.persist()
      if (token) {
        try {
          await bare.post('/auth/logout', { refresh_token: token })
        } catch {
          // best-effort; token is already cleared client-side
        }
      }
    },

    /** Restore the current-user profile from a persisted token on app startup. */
    async restoreSession() {
      if (!this.accessToken) return
      try {
        await this.fetchCurrentUser()
      } catch {
        await this.logout()
      }
    },
  },
})
