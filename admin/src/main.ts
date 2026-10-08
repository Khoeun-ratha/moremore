import { createApp } from 'vue'
import { createPinia } from 'pinia'
import ElementPlus, { ElMessage } from 'element-plus'
import { AxiosError } from 'axios'
import 'element-plus/dist/index.css'
import './style.css'
import App from './App.vue'
import router from './router'
import { extractErrorMessage } from './utils/errorMessage'

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(ElementPlus)

// Safety net for API calls a view awaits without its own catch (list loads, deletes after a
// confirm, ...): without it a failure did nothing visible. Closing a confirm box rejects with
// 'cancel'/'close', which is not an error. 401/403 are already handled by the http client.
function reportUnhandled(reason: unknown): boolean {
  if (reason === 'cancel' || reason === 'close') return true
  if (reason instanceof AxiosError) {
    const status = reason.response?.status
    if (status !== 401 && status !== 403) {
      ElMessage.error(extractErrorMessage(reason, 'Something went wrong. Please try again.'))
    }
    return true
  }
  return false
}

window.addEventListener('unhandledrejection', (event) => {
  if (reportUnhandled(event.reason)) event.preventDefault()
})

app.config.errorHandler = (err) => {
  if (!reportUnhandled(err)) console.error(err)
}

app.mount('#app')
