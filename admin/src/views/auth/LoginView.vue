<script setup lang="ts">
import { reactive, ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Lock, Message } from '@element-plus/icons-vue'
import { useAuthStore } from '../../stores/auth'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()

const form = reactive({ email: '', password: '' })
const loading = ref(false)

onMounted(() => {
  if (route.query.unauthorized) {
    ElMessage.error('That account does not have admin access.')
  }
})

async function handleSubmit() {
  loading.value = true
  try {
    await auth.login(form.email, form.password)
    if (!auth.isAdmin) {
      ElMessage.error('That account does not have admin access.')
      await auth.logout()
      return
    }
    const redirect = (route.query.redirect as string) || '/'
    router.push(redirect)
  } catch (err) {
    ElMessage.error('Invalid email or password.')
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="login-page">
    <div class="login-card">
      <div class="login-card__logo">LP</div>
      <h1 class="login-card__title">Learning Platform</h1>
      <p class="login-card__subtitle">Sign in to manage courses, lessons, and users.</p>

      <el-form label-position="top" @submit.prevent="handleSubmit">
        <el-form-item label="Email">
          <el-input
            v-model="form.email"
            type="email"
            autocomplete="username"
            placeholder="you@example.com"
            :prefix-icon="Message"
            size="large"
          />
        </el-form-item>
        <el-form-item label="Password">
          <el-input
            v-model="form.password"
            type="password"
            autocomplete="current-password"
            placeholder="••••••••"
            show-password
            :prefix-icon="Lock"
            size="large"
          />
        </el-form-item>
        <el-button type="primary" native-type="submit" :loading="loading" size="large" class="login-card__submit">
          Log in
        </el-button>
      </el-form>
    </div>
  </div>
</template>

<style scoped>
.login-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background:
    radial-gradient(circle at 15% 20%, rgba(129, 140, 248, 0.25), transparent 45%),
    radial-gradient(circle at 85% 80%, rgba(99, 102, 241, 0.2), transparent 45%),
    var(--surface-bg);
  padding: 24px;
}

.login-card {
  width: 100%;
  max-width: 380px;
  background: var(--surface-card);
  border: 1px solid var(--surface-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-lg);
  padding: 36px 32px 28px;
}

.login-card__logo {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  background: linear-gradient(135deg, var(--brand-500), var(--brand-700));
  color: #fff;
  font-weight: 700;
  font-size: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 16px;
}

.login-card__title {
  margin: 0 0 4px;
  font-size: 20px;
  font-weight: 700;
  letter-spacing: -0.01em;
}

.login-card__subtitle {
  margin: 0 0 24px;
  color: var(--text-secondary);
  font-size: 13.5px;
}

.login-card__submit {
  width: 100%;
  margin-top: 4px;
}
</style>
