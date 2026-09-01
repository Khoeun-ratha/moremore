<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { Search } from '@element-plus/icons-vue'
import { listFeedback } from '../../api/feedback'
import type { Feedback, FeedbackStatus, FeedbackType } from '../../types/api'

const router = useRouter()

const items = ref<Feedback[]>([])
const total = ref(0)
const page = ref(1)
const pageSize = 10
const searchQuery = ref('')
const typeFilter = ref<FeedbackType | ''>('')
const statusFilter = ref<FeedbackStatus | ''>('')
const loading = ref(false)

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
    const result = await listFeedback({
      q: searchQuery.value || undefined,
      type: typeFilter.value || undefined,
      status: statusFilter.value || undefined,
      page: page.value,
      page_size: pageSize,
    })
    items.value = result.items
    total.value = result.total
  } finally {
    loading.value = false
  }
}

onMounted(load)

function handleFilterChange() {
  page.value = 1
  load()
}

function formatDate(value: string) {
  return new Date(value).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' })
}

function goToDetail(item: Feedback) {
  router.push({ name: 'feedback-detail', params: { id: item.id } })
}
</script>

<template>
  <div class="page-header">
    <div>
      <h2>Feedback &amp; Suggestions</h2>
      <p>General feedback and lesson suggestions submitted by learners from the mobile app.</p>
    </div>
  </div>

  <div class="surface-card">
    <div class="toolbar-row">
      <el-input
        v-model="searchQuery"
        placeholder="Search by subject, message, name, or email"
        style="max-width: 340px"
        clearable
        :prefix-icon="Search"
        @keyup.enter="handleFilterChange"
        @clear="handleFilterChange"
      />
      <el-select v-model="typeFilter" placeholder="All types" clearable style="width: 180px" @change="handleFilterChange">
        <el-option label="Feedback" value="feedback" />
        <el-option label="Lesson suggestion" value="lesson_suggestion" />
      </el-select>
      <el-select v-model="statusFilter" placeholder="All statuses" clearable style="width: 160px" @change="handleFilterChange">
        <el-option label="New" value="new" />
        <el-option label="Reviewed" value="reviewed" />
        <el-option label="Dismissed" value="dismissed" />
      </el-select>
      <el-button @click="handleFilterChange">Search</el-button>
    </div>

    <el-table
      :data="items"
      v-loading="loading"
      stripe
      empty-text="No feedback submitted yet"
      style="cursor: pointer"
      @row-click="goToDetail"
    >
      <el-table-column label="Type" width="160">
        <template #default="{ row }">
          <el-tag :type="typeTagType[row.type as FeedbackType]" round>{{ typeLabel[row.type as FeedbackType] }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="subject" label="Subject" min-width="200" />
      <el-table-column label="Submitted by" min-width="200">
        <template #default="{ row }">
          <div class="submitter-cell">
            <strong>{{ row.user_full_name }}</strong>
            <span>{{ row.user_email }}</span>
          </div>
        </template>
      </el-table-column>
      <el-table-column label="Status" width="130">
        <template #default="{ row }">
          <el-tag :type="statusTagType[row.status as FeedbackStatus]" round>{{ statusLabel[row.status as FeedbackStatus] }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="Submitted" width="140">
        <template #default="{ row }">{{ formatDate(row.created_at) }}</template>
      </el-table-column>
    </el-table>

    <el-pagination
      style="margin-top: 16px; justify-content: flex-end"
      layout="prev, pager, next"
      v-model:current-page="page"
      :page-size="pageSize"
      :total="total"
      @current-change="load"
    />
  </div>
</template>

<style scoped>
.submitter-cell {
  display: flex;
  flex-direction: column;
  line-height: 1.35;
}

.submitter-cell span {
  font-size: 12px;
  color: var(--text-secondary);
}
</style>
