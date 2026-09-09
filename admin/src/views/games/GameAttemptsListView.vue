<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Delete, Search, Trophy } from '@element-plus/icons-vue'
import { deleteGameAttempt, getLeaderboard, listGameAttempts } from '../../api/games'
import type { GameAttemptAdmin, LeaderboardEntry } from '../../types/api'

const items = ref<GameAttemptAdmin[]>([])
const total = ref(0)
const page = ref(1)
const pageSize = 10
const searchQuery = ref('')
const loading = ref(false)

const topPlayer = ref<LeaderboardEntry | null>(null)
const topPlayerLoading = ref(false)

async function load() {
  loading.value = true
  try {
    const result = await listGameAttempts({
      q: searchQuery.value || undefined,
      page: page.value,
      page_size: pageSize,
    })
    items.value = result.items
    total.value = result.total
  } finally {
    loading.value = false
  }
}

async function loadTopPlayer() {
  topPlayerLoading.value = true
  try {
    const board = await getLeaderboard(1)
    topPlayer.value = board[0] ?? null
  } finally {
    topPlayerLoading.value = false
  }
}

onMounted(() => {
  load()
  loadTopPlayer()
})

function handleFilterChange() {
  page.value = 1
  load()
}

function formatDate(value: string) {
  return new Date(value).toLocaleString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  })
}

async function handleDelete(attempt: GameAttemptAdmin) {
  await ElMessageBox.confirm(
    `Remove this Quick Challenge round by ${attempt.user_full_name}? This also removes it from the leaderboard if it was their best.`,
    'Confirm',
    { type: 'warning' },
  )
  await deleteGameAttempt(attempt.id)
  ElMessage.success('Attempt removed')
  await Promise.all([load(), loadTopPlayer()])
}
</script>

<template>
  <div class="page-header">
    <div>
      <h2>Game Attempts</h2>
      <p>Every Quick Challenge round played, and the current leaderboard leader.</p>
    </div>
  </div>

  <div class="surface-card top-player-card" v-loading="topPlayerLoading">
    <div class="top-player-card__icon">
      <el-icon :size="22"><Trophy /></el-icon>
    </div>
    <template v-if="topPlayer">
      <div class="top-player-card__info">
        <span class="top-player-card__label">Current #1</span>
        <strong>{{ topPlayer.full_name }}</strong>
        <span class="top-player-card__meta">{{ topPlayer.score }}/{{ topPlayer.total }} correct &middot; {{ formatDate(topPlayer.achieved_at) }}</span>
      </div>
      <div class="top-player-card__score">{{ topPlayer.percentage.toFixed(0) }}%</div>
    </template>
    <span v-else class="top-player-card__empty">No one has played a Quick Challenge round yet.</span>
  </div>

  <div class="surface-card">
    <div class="toolbar-row">
      <el-input
        v-model="searchQuery"
        placeholder="Search by player name or email"
        style="max-width: 340px"
        clearable
        :prefix-icon="Search"
        @keyup.enter="handleFilterChange"
        @clear="handleFilterChange"
      />
      <el-button @click="handleFilterChange">Search</el-button>
    </div>

    <el-table :data="items" v-loading="loading" stripe empty-text="No game attempts yet">
      <el-table-column label="Player" min-width="200">
        <template #default="{ row }">
          <div class="submitter-cell">
            <strong>{{ row.user_full_name }}</strong>
            <span>{{ row.user_email }}</span>
          </div>
        </template>
      </el-table-column>
      <el-table-column label="Course" min-width="160">
        <template #default="{ row }">{{ row.course_title ?? 'All courses' }}</template>
      </el-table-column>
      <el-table-column label="Score" width="140">
        <template #default="{ row }">
          <el-tag :type="row.percentage >= 70 ? 'success' : 'info'" round>
            {{ row.score }}/{{ row.total }} &middot; {{ row.percentage.toFixed(0) }}%
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="Submitted" width="180">
        <template #default="{ row }">{{ formatDate(row.submitted_at) }}</template>
      </el-table-column>
      <el-table-column label="" width="70">
        <template #default="{ row }">
          <el-button size="small" circle type="danger" :icon="Delete" @click="handleDelete(row)" />
        </template>
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

.top-player-card {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 20px;
  min-height: 32px;
}

.top-player-card__icon {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  background: var(--brand-50);
  color: var(--brand-600);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.top-player-card__info {
  display: flex;
  flex-direction: column;
  line-height: 1.4;
  flex: 1;
}

.top-player-card__label {
  font-size: 11.5px;
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: var(--text-secondary);
}

.top-player-card__meta {
  font-size: 12.5px;
  color: var(--text-secondary);
}

.top-player-card__score {
  font-size: 22px;
  font-weight: 800;
  color: var(--brand-600);
}

.top-player-card__empty {
  color: var(--text-secondary);
  font-size: 13.5px;
}
</style>
