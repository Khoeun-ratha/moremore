<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { ArrowLeft, Delete, Edit, Plus, Reading } from '@element-plus/icons-vue'
import { getCourse } from '../../api/courses'
import { deleteLesson, listLessons } from '../../api/lessons'
import type { CourseDetail, Lesson } from '../../types/api'

const props = defineProps<{ courseId: number }>()
const router = useRouter()

const course = ref<CourseDetail | null>(null)
const lessons = ref<Lesson[]>([])
const loading = ref(false)

async function load() {
  loading.value = true
  try {
    const [courseData, lessonData] = await Promise.all([
      getCourse(props.courseId),
      listLessons(props.courseId),
    ])
    course.value = courseData
    lessons.value = lessonData.sort((a, b) => a.order_index - b.order_index)
  } finally {
    loading.value = false
  }
}

onMounted(load)

function addLesson() {
  router.push({ name: 'lesson-create', params: { courseId: props.courseId } })
}

function editLesson(lesson: Lesson) {
  router.push({ name: 'lesson-edit', params: { id: lesson.id } })
}

function manageQuiz(lesson: Lesson) {
  router.push({ name: 'quiz-edit', params: { id: lesson.id } })
}

async function handleDeleteLesson(lesson: Lesson) {
  await ElMessageBox.confirm(`Delete lesson "${lesson.title}"?`, 'Confirm', { type: 'warning' })
  await deleteLesson(lesson.id)
  ElMessage.success('Lesson deleted')
  await load()
}
</script>

<template>
  <el-button text :icon="ArrowLeft" class="back-link" @click="router.push({ name: 'courses' })">
    Back to courses
  </el-button>

  <div v-if="course">
    <div class="page-header">
      <div>
        <h2>{{ course.title }}</h2>
        <p>{{ course.description }}</p>
      </div>
    </div>

    <div class="surface-card">
      <div class="toolbar-row" style="margin-bottom: 12px">
        <el-icon style="color: var(--brand-600)"><Reading /></el-icon>
        <h3 style="margin: 0; font-size: 15px">Lessons</h3>
        <el-button type="primary" :icon="Plus" style="margin-left: auto" @click="addLesson">Add lesson</el-button>
      </div>

      <el-table :data="lessons" v-loading="loading" stripe>
        <el-table-column prop="order_index" label="#" width="60" />
        <el-table-column prop="title" label="Title" />
        <el-table-column label="Quiz" width="100">
          <template #default="{ row }">
            <el-tag :type="row.has_quiz ? 'success' : 'info'" round>{{ row.has_quiz ? 'Yes' : 'No' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="Actions" width="280" align="right">
          <template #default="{ row }">
            <el-button size="small" :icon="Edit" @click="editLesson(row)">Edit</el-button>
            <el-button size="small" @click="manageQuiz(row)">{{ row.has_quiz ? 'Edit quiz' : 'Add quiz' }}</el-button>
            <el-button size="small" circle type="danger" :icon="Delete" @click="handleDeleteLesson(row)" />
          </template>
        </el-table-column>
      </el-table>
    </div>
  </div>
</template>
