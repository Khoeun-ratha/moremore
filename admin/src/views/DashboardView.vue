<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { Collection, User } from '@element-plus/icons-vue'
import { listCourses } from '../api/courses'
import { listUsers } from '../api/users'

const courseCount = ref<number | null>(null)
const userCount = ref<number | null>(null)
const loading = ref(true)

onMounted(async () => {
  try {
    const [courses, users] = await Promise.all([
      listCourses({ page: 1, page_size: 1 }),
      listUsers(),
    ])
    courseCount.value = courses.total
    userCount.value = users.length
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="page-header">
    <div>
      <h2>Overview</h2>
      <p>A quick snapshot of your platform's content and members.</p>
    </div>
  </div>

  <el-row :gutter="20" v-loading="loading">
    <el-col :span="6">
      <div class="stat-card">
        <div class="stat-card__icon stat-card__icon--indigo">
          <el-icon><Collection /></el-icon>
        </div>
        <div class="stat-card__value">{{ courseCount ?? '—' }}</div>
        <div class="stat-card__label">Courses</div>
      </div>
    </el-col>
    <el-col :span="6">
      <div class="stat-card">
        <div class="stat-card__icon stat-card__icon--teal">
          <el-icon><User /></el-icon>
        </div>
        <div class="stat-card__value">{{ userCount ?? '—' }}</div>
        <div class="stat-card__label">Users</div>
      </div>
    </el-col>
  </el-row>
</template>

<style scoped>
.stat-card {
  background: var(--surface-card);
  border: 1px solid var(--surface-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
  padding: 20px;
  transition: box-shadow 0.15s ease, transform 0.15s ease;
}

.stat-card:hover {
  box-shadow: var(--shadow-md);
  transform: translateY(-1px);
}

.stat-card__icon {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  color: #fff;
  margin-bottom: 14px;
}

.stat-card__icon--indigo {
  background: linear-gradient(135deg, var(--brand-400), var(--brand-600));
}

.stat-card__icon--teal {
  background: linear-gradient(135deg, #34d399, #0d9488);
}

.stat-card__value {
  font-size: 30px;
  font-weight: 700;
  letter-spacing: -0.02em;
  line-height: 1.2;
}

.stat-card__label {
  color: var(--text-secondary);
  font-size: 13.5px;
  margin-top: 2px;
}
</style>
