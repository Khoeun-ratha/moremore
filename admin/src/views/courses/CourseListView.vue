<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Delete, Edit, Plus, Search } from '@element-plus/icons-vue'
import { createCourse, deleteCourse, listCourses, updateCourse, type CourseInput } from '../../api/courses'
import type { Course } from '../../types/api'
import FileUploader from '../../components/FileUploader.vue'
import { mediaUrl } from '../../utils/media'

const router = useRouter()

const courses = ref<Course[]>([])
const total = ref(0)
const page = ref(1)
const pageSize = 10
const searchQuery = ref('')
const loading = ref(false)

const dialogVisible = ref(false)
const editingCourse = ref<Course | null>(null)
const form = reactive<CourseInput>({
  title: '',
  description: '',
  category: '',
  level: 'beginner',
  cover_image_url: null,
})
const saving = ref(false)

const levelTagType: Record<string, 'success' | 'warning' | 'danger'> = {
  beginner: 'success',
  intermediate: 'warning',
  advanced: 'danger',
}

async function load() {
  loading.value = true
  try {
    const result = await listCourses({ q: searchQuery.value || undefined, page: page.value, page_size: pageSize })
    courses.value = result.items
    total.value = result.total
  } finally {
    loading.value = false
  }
}

onMounted(load)

function openCreateDialog() {
  editingCourse.value = null
  Object.assign(form, { title: '', description: '', category: '', level: 'beginner', cover_image_url: null })
  dialogVisible.value = true
}

function openEditDialog(course: Course) {
  editingCourse.value = course
  Object.assign(form, {
    title: course.title,
    description: course.description,
    category: course.category,
    level: course.level,
    cover_image_url: course.cover_image_url,
  })
  dialogVisible.value = true
}

async function handleSave() {
  saving.value = true
  try {
    if (editingCourse.value) {
      await updateCourse(editingCourse.value.id, form)
      ElMessage.success('Course updated')
    } else {
      await createCourse(form)
      ElMessage.success('Course created')
    }
    dialogVisible.value = false
    await load()
  } catch {
    ElMessage.error('Could not save the course. Check the fields and try again.')
  } finally {
    saving.value = false
  }
}

async function handleDelete(course: Course) {
  await ElMessageBox.confirm(`Delete "${course.title}"? This also deletes its lessons and quizzes.`, 'Confirm', {
    type: 'warning',
  })
  await deleteCourse(course.id)
  ElMessage.success('Course deleted')
  await load()
}

function goToDetail(course: Course) {
  router.push({ name: 'course-detail', params: { id: course.id } })
}
</script>

<template>
  <div class="page-header">
    <div>
      <h2>Courses</h2>
      <p>Create and manage the courses available on your platform.</p>
    </div>
    <div class="page-header__actions">
      <el-button type="primary" :icon="Plus" @click="openCreateDialog">New course</el-button>
    </div>
  </div>

  <div class="surface-card">
    <div class="toolbar-row">
      <el-input
        v-model="searchQuery"
        placeholder="Search by title or description"
        style="max-width: 320px"
        clearable
        :prefix-icon="Search"
        @keyup.enter="load"
        @clear="load"
      />
      <el-button @click="load">Search</el-button>
    </div>

    <el-table :data="courses" v-loading="loading" @row-click="goToDetail" style="cursor: pointer" stripe>
      <el-table-column label="Cover" width="72">
        <template #default="{ row }">
          <el-image
            v-if="row.cover_image_url"
            :src="mediaUrl(row.cover_image_url)"
            fit="cover"
            style="width: 40px; height: 40px; border-radius: 4px"
          />
        </template>
      </el-table-column>
      <el-table-column prop="title" label="Title" />
      <el-table-column prop="category" label="Category" width="160" />
      <el-table-column label="Level" width="140">
        <template #default="{ row }">
          <el-tag :type="levelTagType[row.level] ?? 'info'" round>{{ row.level }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="Actions" width="140" align="right">
        <template #default="{ row }">
          <el-button size="small" circle :icon="Edit" @click.stop="openEditDialog(row)" />
          <el-button size="small" circle type="danger" :icon="Delete" @click.stop="handleDelete(row)" />
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

  <el-dialog v-model="dialogVisible" :title="editingCourse ? 'Edit course' : 'New course'" width="480px">
    <el-form label-position="top">
      <el-form-item label="Title">
        <el-input v-model="form.title" />
      </el-form-item>
      <el-form-item label="Description">
        <el-input v-model="form.description" type="textarea" :rows="3" />
      </el-form-item>
      <el-form-item label="Category">
        <el-input v-model="form.category" />
      </el-form-item>
      <el-form-item label="Level">
        <el-select v-model="form.level" style="width: 100%">
          <el-option label="Beginner" value="beginner" />
          <el-option label="Intermediate" value="intermediate" />
          <el-option label="Advanced" value="advanced" />
        </el-select>
      </el-form-item>
      <el-form-item label="Cover image">
        <FileUploader kind="image" v-model="form.cover_image_url" />
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button @click="dialogVisible = false">Cancel</el-button>
      <el-button type="primary" :loading="saving" @click="handleSave">Save</el-button>
    </template>
  </el-dialog>
</template>
