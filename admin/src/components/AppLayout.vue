<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ArrowDown, ChatDotRound, Collection, DataLine, Medal, SwitchButton, User as UserIcon } from '@element-plus/icons-vue'
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
  background: var(--surface-card);
  border-right: 1px solid var(--surface-border);
  display: flex;
  flex-direction: column;
}

.app-sidebar__brand {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 20px 18px;
}

.app-sidebar__logo {
  width: 32px;
  height: 32px;
  border-radius: 9px;
  background: linear-gradient(135deg, var(--brand-500), var(--brand-700));
  color: #fff;
  font-weight: 700;
  font-size: 13px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.app-sidebar__brand-text {
  font-weight: 600;
  font-size: 15px;
  letter-spacing: -0.01em;
}

.app-sidebar__menu {
  border-right: none;
  padding: 4px 10px;
}

.app-sidebar__menu :deep(.el-menu-item) {
  border-radius: 8px;
  margin-bottom: 4px;
  gap: 10px;
}

.app-sidebar__menu :deep(.el-menu-item.is-active) {
  background: var(--brand-50);
  color: var(--brand-600);
  font-weight: 600;
}

.app-header {
  background: var(--surface-card);
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
  background: var(--surface-bg);
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
  padding: 24px;
}
</style>
