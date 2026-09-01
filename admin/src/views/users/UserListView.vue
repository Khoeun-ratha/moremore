<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { TrendCharts } from '@element-plus/icons-vue'
import { listUsers, updateUser } from '../../api/users'
import type { User } from '../../types/api'

const router = useRouter()
const users = ref<User[]>([])
const loading = ref(false)

async function load() {
  loading.value = true
  try {
    users.value = await listUsers()
  } finally {
    loading.value = false
  }
}

onMounted(load)

async function toggleRole(user: User) {
  const newRole = user.role === 'admin' ? 'user' : 'admin'
  try {
    await updateUser(user.id, { role: newRole })
    ElMessage.success(`${user.email} is now ${newRole}`)
    await load()
  } catch {
    ElMessage.error('Could not update role.')
  }
}

async function toggleActive(user: User) {
  try {
    await updateUser(user.id, { is_active: !user.is_active })
    await load()
  } catch {
    ElMessage.error('Could not update status.')
  }
}

function viewProgress(user: User) {
  router.push({ name: 'user-progress', params: { id: user.id } })
}
</script>

<template>
  <div class="page-header">
    <div>
      <h2>Users</h2>
      <p>Manage member access, roles, and account status.</p>
    </div>
  </div>

  <div class="surface-card">
    <el-table :data="users" v-loading="loading" stripe>
      <el-table-column prop="email" label="Email" />
      <el-table-column prop="full_name" label="Name" />
      <el-table-column label="Role" width="140">
        <template #default="{ row }">
          <el-tag :type="row.role === 'admin' ? 'success' : 'info'" round>{{ row.role }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="Active" width="100">
        <template #default="{ row }">
          <el-switch :model-value="row.is_active" @change="toggleActive(row)" />
        </template>
      </el-table-column>
      <el-table-column label="Actions" width="280" align="right">
        <template #default="{ row }">
          <el-button size="small" :icon="TrendCharts" @click="viewProgress(row)">Progress</el-button>
          <el-button size="small" @click="toggleRole(row)">
            {{ row.role === 'admin' ? 'Revoke admin' : 'Make admin' }}
          </el-button>
        </template>
      </el-table-column>
    </el-table>
  </div>
</template>
