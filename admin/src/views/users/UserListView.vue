<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { ArrowDown, Edit, TrendCharts } from '@element-plus/icons-vue'
import type { AxiosError } from 'axios'
import { listUsers, resetUserPassword, updateUser } from '../../api/users'
import type { User, UserRole } from '../../types/api'
import { useAuthStore } from '../../stores/auth'

function errorMessage(err: unknown, fallback: string): string {
  const data = (err as AxiosError)?.response?.data as { error?: string } | undefined
  return data?.error ?? fallback
}

const auth = useAuthStore()
const router = useRouter()
const users = ref<User[]>([])
const loading = ref(false)

const roleTagType: Record<UserRole, 'info' | 'success' | 'danger'> = {
  user: 'info',
  admin: 'success',
  super_admin: 'danger',
}

const roleLabel: Record<UserRole, string> = {
  user: 'user',
  admin: 'admin',
  super_admin: 'super admin',
}

/** Only a super admin may manage another admin/super-admin account; anyone
 * with admin access can still manage a plain user. Mirrors the backend's
 * `_require_super_admin_for_admin_target` check. */
function canManage(user: User): boolean {
  return auth.isSuperAdmin || user.role === 'user'
}

async function load() {
  loading.value = true
  try {
    users.value = await listUsers()
  } finally {
    loading.value = false
  }
}

onMounted(load)

async function setRole(user: User, role: UserRole) {
  if (role === user.role) return
  try {
    await updateUser(user.id, { role })
    ElMessage.success(`${user.email} is now ${roleLabel[role]}`)
    await load()
  } catch (err) {
    ElMessage.error(errorMessage(err, 'Could not update role.'))
  }
}

async function toggleActive(user: User) {
  try {
    await updateUser(user.id, { is_active: !user.is_active })
    await load()
  } catch (err) {
    ElMessage.error(errorMessage(err, 'Could not update status.'))
  }
}

function viewProgress(user: User) {
  router.push({ name: 'user-progress', params: { id: user.id } })
}

const dialogVisible = ref(false)
const editingUser = ref<User | null>(null)
const form = reactive({ full_name: '', email: '', new_password: '' })
const saving = ref(false)

function openEditDialog(user: User) {
  editingUser.value = user
  Object.assign(form, { full_name: user.full_name, email: user.email, new_password: '' })
  dialogVisible.value = true
}

async function handleSave() {
  const user = editingUser.value
  if (!user) return

  if (form.new_password && form.new_password.length < 8) {
    ElMessage.error('New password must be at least 8 characters.')
    return
  }

  if (form.new_password) {
    try {
      await ElMessageBox.confirm(
        `This immediately signs ${user.email} out of every device. Continue?`,
        'Reset password',
        { type: 'warning' },
      )
    } catch {
      return
    }
  }

  saving.value = true
  try {
    const profileChanges: Partial<Pick<User, 'full_name' | 'email'>> = {}
    if (form.full_name !== user.full_name) profileChanges.full_name = form.full_name
    if (form.email !== user.email) profileChanges.email = form.email
    if (Object.keys(profileChanges).length > 0) {
      await updateUser(user.id, profileChanges)
    }
    if (form.new_password) {
      await resetUserPassword(user.id, form.new_password)
    }
    ElMessage.success('User updated')
    dialogVisible.value = false
    await load()
  } catch (err) {
    ElMessage.error(errorMessage(err, 'Could not save changes.'))
  } finally {
    saving.value = false
  }
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
      <el-table-column label="Role" width="160">
        <template #default="{ row }">
          <el-dropdown v-if="auth.isSuperAdmin" trigger="click" @command="(role: UserRole) => setRole(row, role)">
            <el-tag :type="roleTagType[row.role as UserRole]" round style="cursor: pointer">
              {{ roleLabel[row.role as UserRole] }}
              <el-icon style="vertical-align: -2px"><ArrowDown /></el-icon>
            </el-tag>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="user" :disabled="row.role === 'user'">User</el-dropdown-item>
                <el-dropdown-item command="admin" :disabled="row.role === 'admin'">Admin</el-dropdown-item>
                <el-dropdown-item command="super_admin" :disabled="row.role === 'super_admin'">
                  Super admin
                </el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
          <el-tag v-else :type="roleTagType[row.role as UserRole]" round>{{ roleLabel[row.role as UserRole] }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="Active" width="100">
        <template #default="{ row }">
          <el-switch :model-value="row.is_active" :disabled="!canManage(row)" @change="toggleActive(row)" />
        </template>
      </el-table-column>
      <el-table-column label="Actions" width="220" align="right">
        <template #default="{ row }">
          <el-button size="small" circle :icon="Edit" :disabled="!canManage(row)" @click="openEditDialog(row)" />
          <el-button size="small" :icon="TrendCharts" @click="viewProgress(row)">Progress</el-button>
        </template>
      </el-table-column>
    </el-table>
  </div>

  <el-dialog v-model="dialogVisible" title="Edit user" width="420px">
    <el-form label-position="top">
      <el-form-item label="Email">
        <el-input v-model="form.email" type="email" />
      </el-form-item>
      <el-form-item label="Full name">
        <el-input v-model="form.full_name" />
      </el-form-item>
      <el-form-item label="New password">
        <el-input v-model="form.new_password" type="password" show-password placeholder="Leave blank to keep unchanged" />
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button @click="dialogVisible = false">Cancel</el-button>
      <el-button type="primary" :loading="saving" @click="handleSave">Save</el-button>
    </template>
  </el-dialog>
</template>
