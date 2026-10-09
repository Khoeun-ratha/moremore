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

      <div class="login-card__legal-links">
        <router-link :to="{ name: 'terms-of-service' }">Terms &amp; Conditions</router-link>
        <span>·</span>
        <router-link :to="{ name: 'privacy-policy' }">Privacy Policy</router-link>
      </div>
    </div>
  </div>
</template>

<style scoped>
.login-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}

.login-card {
  width: 100%;
  max-width: 400px;
  background: var(--surface-glass-strong);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.8);
  border-radius: 24px;
  box-shadow: var(--shadow-lg);
  padding: 40px 34px 30px;
  animation: card-in 0.6s var(--ease-out) both;
}

@keyframes card-in {
  from {
    opacity: 0;
    transform: translateY(18px) scale(0.98);
  }
}

.login-card__logo {
  width: 52px;
  height: 52px;
  border-radius: 16px;
  background: linear-gradient(135deg, var(--brand-400), var(--brand-700));
  box-shadow: 0 10px 24px rgba(108, 76, 240, 0.4);
  animation: logo-float 4s ease-in-out infinite;
  color: #fff;
  font-weight: 700;
  font-size: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 16px;
}

@keyframes logo-float {
  50% {
    transform: translateY(-4px);
  }
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
  margin-top: 8px;
  height: 46px;
  font-weight: 600;
}

.login-card__legal-links {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  margin-top: 18px;
  font-size: 12.5px;
  color: var(--text-secondary);
}

.login-card__legal-links a {
  color: var(--text-secondary);
  text-decoration: none;
}

.login-card__legal-links a:hover {
  color: var(--brand-600);
  text-decoration: underline;
}
</style>
