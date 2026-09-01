<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { ArrowLeft, Check, Close } from '@element-plus/icons-vue'
import { getFeedback, updateFeedbackStatus } from '../../api/feedback'
import type { Feedback, FeedbackStatus, FeedbackType } from '../../types/api'

const props = defineProps<{ feedbackId: number }>()
const router = useRouter()

const feedback = ref<Feedback | null>(null)
const loading = ref(true)
const updating = ref(false)

const typeTagType: Record<FeedbackType, 'info' | 'warning'> = {
  feedback: 'info',
  lesson_suggestion: 'warning',
}

const typeLabel: Record<FeedbackType, string> = {
  feedback: 'Feedback',
  lesson_suggestion: 'Lesson suggestion',
}

const statusTagType: Record<FeedbackStatus, '' | 'success' | 'info'> = {
  new: '',
  reviewed: 'success',
  dismissed: 'info',
}

const statusLabel: Record<FeedbackStatus, string> = {
  new: 'New',
  reviewed: 'Reviewed',
  dismissed: 'Dismissed',
}

async function load() {
  loading.value = true
  try {
    feedback.value = await getFeedback(props.feedbackId)
  } finally {
    loading.value = false
  }
}

onMounted(load)

function formatDate(value: string) {
  return new Date(value).toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  })
}

async function setStatus(status: FeedbackStatus) {
  if (!feedback.value) return
  updating.value = true
  try {
    feedback.value = await updateFeedbackStatus(feedback.value.id, status)
    ElMessage.success(`Marked as ${statusLabel[status].toLowerCase()}`)
  } catch {
    ElMessage.error('Could not update the status. Try again.')
  } finally {
    updating.value = false
  }
}
</script>

<template>
  <el-button text :icon="ArrowLeft" class="back-link" @click="router.push({ name: 'feedback' })">
    Back to feedback
  </el-button>

  <div class="page-header">
    <div>
      <h2>Feedback detail</h2>
      <p>Submitted from the mobile app.</p>
    </div>
    <div class="page-header__actions" v-if="feedback">
      <el-button
        :icon="Check"
        :loading="updating"
        :disabled="feedback.status === 'reviewed'"
        @click="setStatus('reviewed')"
      >
        Mark reviewed
      </el-button>
      <el-button
        :icon="Close"
        :loading="updating"
        :disabled="feedback.status === 'dismissed'"
        @click="setStatus('dismissed')"
      >
        Dismiss
      </el-button>
    </div>
  </div>

  <div v-loading="loading">
    <template v-if="feedback">
      <div class="surface-card details-card">
        <div class="details-card__header">
          <el-tag :type="typeTagType[feedback.type]" round>{{ typeLabel[feedback.type] }}</el-tag>
          <el-tag :type="statusTagType[feedback.status]" round>{{ statusLabel[feedback.status] }}</el-tag>
        </div>

        <h3 class="details-card__subject">{{ feedback.subject }}</h3>
        <p class="details-card__message">{{ feedback.message }}</p>

        <div class="details-row">
          <span class="details-row__label">Submitted by</span>
          <span class="details-row__value">{{ feedback.user_full_name }} ({{ feedback.user_email }})</span>
        </div>
        <div class="details-row">
          <span class="details-row__label">Submitted</span>
          <span class="details-row__value">{{ formatDate(feedback.created_at) }}</span>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.details-card {
  max-width: 640px;
  margin: 0 auto;
}

.details-card__header {
  display: flex;
  gap: 8px;
  margin-bottom: 16px;
}

.details-card__subject {
  margin: 0 0 8px;
  font-size: 18px;
  font-weight: 700;
}

.details-card__message {
  margin: 0 0 20px;
  font-size: 14px;
  line-height: 1.6;
  color: var(--text-primary);
  white-space: pre-wrap;
}

.details-row {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  padding: 10px 0;
  border-bottom: 1px solid var(--surface-border);
  font-size: 13.5px;
}

.details-row:last-child {
  border-bottom: none;
}

.details-row__label {
  color: var(--text-secondary);
}

.details-row__value {
  font-weight: 500;
  text-align: right;
}
</style>
