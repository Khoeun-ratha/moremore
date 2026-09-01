<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { Search, TrendCharts } from '@element-plus/icons-vue'
import { listCertificates } from '../../api/certificates'
import type { Certificate } from '../../types/api'

const router = useRouter()

const certificates = ref<Certificate[]>([])
const total = ref(0)
const page = ref(1)
const pageSize = 10
const searchQuery = ref('')
const loading = ref(false)

async function load() {
  loading.value = true
  try {
    const result = await listCertificates({ q: searchQuery.value || undefined, page: page.value, page_size: pageSize })
    certificates.value = result.items
    total.value = result.total
  } finally {
    loading.value = false
  }
}

onMounted(load)

function formatDate(value: string) {
  return new Date(value).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' })
}

function viewProgress(certificate: Certificate) {
  router.push({ name: 'user-progress', params: { id: certificate.user_id } })
}

function goToDetail(certificate: Certificate) {
  router.push({ name: 'certificate-detail', params: { id: certificate.id } })
}
</script>

<template>
  <div class="page-header">
    <div>
      <h2>Certificates</h2>
      <p>Every certificate issued to learners across all courses.</p>
    </div>
  </div>

  <div class="surface-card">
    <div class="toolbar-row">
      <el-input
        v-model="searchQuery"
        placeholder="Search by learner name, email, course, or certificate number"
        style="max-width: 380px"
        clearable
        :prefix-icon="Search"
        @keyup.enter="load"
        @clear="load"
      />
      <el-button @click="load">Search</el-button>
    </div>

    <el-table
      :data="certificates"
      v-loading="loading"
      stripe
      empty-text="No certificates issued yet"
      style="cursor: pointer"
      @row-click="goToDetail"
    >
      <el-table-column label="Learner" min-width="200">
        <template #default="{ row }">
          <div class="learner-cell">
            <strong>{{ row.user_full_name }}</strong>
            <span>{{ row.user_email }}</span>
          </div>
        </template>
      </el-table-column>
      <el-table-column prop="course_title" label="Course" min-width="180" />
      <el-table-column label="Certificate number" width="200">
        <template #default="{ row }">
          <code>{{ row.certificate_number }}</code>
        </template>
      </el-table-column>
      <el-table-column label="Issued" width="140">
        <template #default="{ row }">{{ formatDate(row.issued_at) }}</template>
      </el-table-column>
      <el-table-column label="" width="120" align="right">
        <template #default="{ row }">
          <el-button size="small" :icon="TrendCharts" @click.stop="viewProgress(row)">Progress</el-button>
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
.learner-cell {
  display: flex;
  flex-direction: column;
  line-height: 1.35;
}

.learner-cell span {
  font-size: 12px;
  color: var(--text-secondary);
}

code {
  font-size: 12.5px;
  background: var(--brand-50);
  color: var(--brand-700);
  padding: 2px 6px;
  border-radius: 6px;
}
</style>
