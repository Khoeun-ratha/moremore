<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ArrowLeft, Medal } from '@element-plus/icons-vue'
import { getUser, getUserProgress } from '../../api/users'
import type { OverallProgress, User } from '../../types/api'

const props = defineProps<{ userId: number }>()
const router = useRouter()

const user = ref<User | null>(null)
const progress = ref<OverallProgress | null>(null)
const loading = ref(true)

onMounted(async () => {
  try {
    const [userData, progressData] = await Promise.all([getUser(props.userId), getUserProgress(props.userId)])
    user.value = userData
    progress.value = progressData
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <el-button text :icon="ArrowLeft" class="back-link" @click="router.push({ name: 'users' })">
    Back to users
  </el-button>

  <div v-loading="loading">
    <div class="page-header" v-if="user">
      <div>
        <h2>{{ user.full_name }}</h2>
        <p>{{ user.email }}</p>
      </div>
      <div class="page-header__actions" v-if="progress">
        <div class="progress-badge">
          <span class="progress-badge__value">{{ progress.overall_percentage }}%</span>
          <span class="progress-badge__label">Overall progress</span>
        </div>
      </div>
    </div>

    <div class="surface-card" v-if="progress">
      <el-table :data="progress.courses" empty-text="Not enrolled in any course yet" stripe>
        <el-table-column prop="course_title" label="Course" />
        <el-table-column label="Lessons completed" width="180">
          <template #default="{ row }">{{ row.completed_lessons }} / {{ row.total_lessons }}</template>
        </el-table-column>
        <el-table-column label="Progress" width="240">
          <template #default="{ row }">
            <el-progress :percentage="row.percentage" :stroke-width="8" />
          </template>
        </el-table-column>
        <el-table-column label="Certificate" width="160">
          <template #default="{ row }">
            <el-tooltip v-if="row.certificate_number" :content="row.certificate_number">
              <el-tag type="warning" round :icon="Medal">Issued</el-tag>
            </el-tooltip>
            <span v-else class="text-muted">—</span>
          </template>
        </el-table-column>
      </el-table>
    </div>
  </div>
</template>

<style scoped>
.progress-badge {
  background: var(--brand-50);
  border-radius: var(--radius-md);
  padding: 8px 16px;
  text-align: center;
}

.progress-badge__value {
  display: block;
  font-size: 20px;
  font-weight: 700;
  color: var(--brand-600);
  line-height: 1.2;
}

.progress-badge__label {
  font-size: 12px;
  color: var(--text-secondary);
}

.text-muted {
  color: var(--text-secondary);
}
</style>
