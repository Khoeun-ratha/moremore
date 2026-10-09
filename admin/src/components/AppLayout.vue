<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  ArrowDown,
  ChatDotRound,
  Collection,
  DataLine,
  Document,
  Lock,
  Medal,
  SwitchButton,
  Trophy,
  User as UserIcon,
} from '@element-plus/icons-vue'
import { useAuthStore } from '../stores/auth'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()

const navItems = [
  { path: '/', label: 'Dashboard', icon: DataLine },
  { path: '/courses', label: 'Courses', icon: Collection },
  { path: '/users', label: 'Users', icon: UserIcon },
  { path: '/certificates', label: 'Certificates', icon: Medal },
  { path: '/feedback', label: 'Feedback', icon: ChatDotRound },
  { path: '/game-attempts', label: 'Game Attempts', icon: Trophy },
  { path: '/terms-of-service', label: 'Terms & Conditions', icon: Document },
  { path: '/privacy-policy', label: 'Privacy Policy', icon: Lock },
]

const activeMenuPath = computed(() => {
  const match = navItems
    .filter((item) => item.path === '/' ? route.path === '/' : route.path.startsWith(item.path))
    .sort((a, b) => b.path.length - a.path.length)[0]
  return match?.path ?? '/'
})

const pageTitle = computed(() => (route.meta.title as string) ?? 'Learning Platform Admin')

const userLabel = computed(() => auth.user?.full_name ?? auth.user?.email ?? '')
const userInitial = computed(() => userLabel.value.charAt(0).toUpperCase() || '?')

async function handleLogout() {
  await auth.logout()
  router.push({ name: 'login' })
}
</script>

<template>
  <el-container style="min-height: 100vh">
    <el-aside width="232px" class="app-sidebar">
      <div class="app-sidebar__brand">
        <div class="app-sidebar__logo">LP</div>
        <span class="app-sidebar__brand-text">Learning Platform</span>
      </div>
      <el-menu :default-active="activeMenuPath" router class="app-sidebar__menu">
        <el-menu-item v-for="item in navItems" :key="item.path" :index="item.path">
          <el-icon><component :is="item.icon" /></el-icon>
          <span>{{ item.label }}</span>
        </el-menu-item>
      </el-menu>
    </el-aside>
    <el-container>
      <el-header class="app-header">
        <h1 class="app-header__title">{{ pageTitle }}</h1>
        <el-dropdown trigger="click">
          <div class="app-header__user">
            <div class="app-header__avatar">{{ userInitial }}</div>
            <span class="app-header__name">{{ userLabel }}</span>
            <el-icon class="app-header__caret"><ArrowDown /></el-icon>
          </div>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item :icon="SwitchButton" @click="handleLogout">Log out</el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </el-header>
      <el-main class="app-main">
        <slot />
      </el-main>
    </el-container>
  </el-container>
</template>

<style scoped>
.app-sidebar {
  background: var(--surface-glass);
  backdrop-filter: blur(18px);
  border-right: 1px solid var(--surface-border);
  display: flex;
  flex-direction: column;
  position: sticky;
  top: 0;
  height: 100vh;
}

.app-sidebar__brand {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 20px 18px;
}

.app-sidebar__logo {
  width: 34px;
  height: 34px;
  border-radius: 10px;
  background: linear-gradient(135deg, var(--brand-400), var(--brand-700));
  box-shadow: 0 6px 16px rgba(108, 76, 240, 0.35);
  transition: transform 0.4s var(--ease-out);
  color: #fff;
  font-weight: 700;
  font-size: 13px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.app-sidebar__brand:hover .app-sidebar__logo {
  transform: rotate(-8deg) scale(1.06);
}

.app-sidebar__brand-text {
  font-weight: 600;
  font-size: 15px;
  letter-spacing: -0.01em;
}

.app-sidebar__menu {
  --el-menu-bg-color: transparent;
  --el-menu-hover-bg-color: rgba(108, 76, 240, 0.07);
  border-right: none;
  padding: 4px 10px;
}

.app-sidebar__menu :deep(.el-menu-item) {
  position: relative;
  border-radius: 10px;
  margin-bottom: 4px;
  gap: 10px;
  transition: background-color 0.2s ease, color 0.2s ease, transform 0.2s var(--ease-out);
}

.app-sidebar__menu :deep(.el-menu-item:hover) {
  transform: translateX(3px);
}

.app-sidebar__menu :deep(.el-menu-item.is-active) {
  background: linear-gradient(90deg, rgba(108, 76, 240, 0.16), rgba(108, 76, 240, 0.04));
  color: var(--brand-600);
  font-weight: 600;
}

.app-sidebar__menu :deep(.el-menu-item.is-active)::before {
  content: '';
  position: absolute;
  left: -10px;
  top: 10px;
  bottom: 10px;
  width: 4px;
  border-radius: 0 4px 4px 0;
  background: linear-gradient(180deg, var(--brand-400), var(--brand-600));
  animation: indicator-in 0.3s var(--ease-out);
}

@keyframes indicator-in {
  from {
    transform: scaleY(0);
  }
}

.app-header {
  background: var(--surface-glass);
  backdrop-filter: blur(18px);
  border-bottom: 1px solid var(--surface-border);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px;
  position: sticky;
  top: 0;
  z-index: 10;
}

.app-header__title {
  margin: 0;
  font-size: 17px;
  font-weight: 700;
  letter-spacing: -0.01em;
}

.app-header__user {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 10px;
  border-radius: 999px;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.app-header__user:hover {
  background: rgba(108, 76, 240, 0.08);
}

.app-header__avatar {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--brand-400), var(--brand-600));
  color: #fff;
  font-size: 12px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.app-header__name {
  font-size: 13.5px;
  font-weight: 500;
  color: var(--text-primary);
}

.app-header__caret {
  color: var(--text-secondary);
  font-size: 12px;
}

.app-main {
  padding: 24px 28px 40px;
}
</style>
