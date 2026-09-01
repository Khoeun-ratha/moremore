<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { ArrowLeft, DocumentCopy, InfoFilled, VideoPlay } from '@element-plus/icons-vue'
import { createLesson, getLesson, updateLesson, type LessonInput } from '../../api/lessons'
import FileUploader from '../../components/FileUploader.vue'

const props = defineProps<{ courseId?: number; lessonId?: number }>()
const router = useRouter()

const isEditing = !!props.lessonId
const courseId = ref<number | null>(props.courseId ?? null)
const loading = ref(false)
const saving = ref(false)

const YOUTUBE_URL_RE = /^https?:\/\/(www\.)?(youtube\.com|youtu\.be)\//i

const form = reactive<LessonInput>({
  title: '',
  order_index: 0,
  content: '',
  video_url: null,
  file_url: null,
})

const videoSource = ref<'upload' | 'youtube'>('upload')

onMounted(async () => {
  if (props.lessonId) {
    loading.value = true
    try {
      const lesson = await getLesson(props.lessonId)
      courseId.value = lesson.course_id
      Object.assign(form, {
        title: lesson.title,
        order_index: lesson.order_index,
        content: lesson.content,
        video_url: lesson.video_url,
        file_url: lesson.file_url,
      })
      videoSource.value = form.video_url && YOUTUBE_URL_RE.test(form.video_url) ? 'youtube' : 'upload'
    } finally {
      loading.value = false
    }
  }
})

function handleVideoSourceChange(value: 'upload' | 'youtube') {
  const isYoutube = !!form.video_url && YOUTUBE_URL_RE.test(form.video_url)
  if (value === 'youtube' && !isYoutube) form.video_url = null
  if (value === 'upload' && isYoutube) form.video_url = null
}

async function handleSave() {
  if (!form.title.trim()) {
    ElMessage.error('Title is required')
    return
  }
  if (videoSource.value === 'youtube' && form.video_url && !YOUTUBE_URL_RE.test(form.video_url)) {
    ElMessage.error('Enter a valid YouTube URL (youtube.com or youtu.be)')
    return
  }
  saving.value = true
  try {
    if (isEditing && props.lessonId) {
      await updateLesson(props.lessonId, form)
      ElMessage.success('Lesson updated')
    } else if (courseId.value) {
      await createLesson(courseId.value, form)
      ElMessage.success('Lesson created')
    }
    router.push({ name: 'course-detail', params: { id: courseId.value } })
  } catch {
    ElMessage.error('Could not save the lesson.')
  } finally {
    saving.value = false
  }
}

function goBack() {
  router.push({ name: 'course-detail', params: { id: courseId.value } })
}
</script>

<template>
  <el-button text :icon="ArrowLeft" class="back-link" @click="goBack"> Back to course </el-button>

  <div class="page-header">
    <div>
      <h2>{{ isEditing ? 'Edit lesson' : 'New lesson' }}</h2>
      <p>Set the content, media, and ordering for this lesson.</p>
    </div>
  </div>

  <el-form label-position="top" v-loading="loading" class="lesson-form">
    <section class="form-section">
      <header class="form-section__header">
        <span class="form-section__icon"><el-icon><InfoFilled /></el-icon></span>
        <div>
          <h3>Lesson details</h3>
          <p>The title, ordering, and written content students will see.</p>
        </div>
      </header>

      <div class="form-section__body">
        <div class="form-row form-row--split">
          <el-form-item label="Title" required class="form-row--grow">
            <el-input v-model="form.title" placeholder="e.g. Introduction to variables" />
          </el-form-item>
          <el-form-item label="Order">
            <el-input-number v-model="form.order_index" :min="0" style="width: 120px" />
          </el-form-item>
        </div>
        <el-form-item label="Content / description">
          <el-input v-model="form.content" type="textarea" :rows="6" placeholder="Write the lesson content here..." />
        </el-form-item>
      </div>
    </section>

    <section class="form-section">
      <header class="form-section__header">
        <span class="form-section__icon"><el-icon><VideoPlay /></el-icon></span>
        <div>
          <h3>Video</h3>
          <p>Upload a video file, or link to a YouTube video instead.</p>
        </div>
      </header>

      <div class="form-section__body">
        <el-radio-group v-model="videoSource" class="video-source-toggle" @change="handleVideoSourceChange">
          <el-radio-button value="upload">Upload file</el-radio-button>
          <el-radio-button value="youtube">YouTube link</el-radio-button>
        </el-radio-group>
        <FileUploader v-if="videoSource === 'upload'" kind="video" v-model="form.video_url" />
        <el-input
          v-else
          v-model="form.video_url"
          placeholder="https://www.youtube.com/watch?v=..."
          clearable
        />
      </div>
    </section>

    <section class="form-section">
      <header class="form-section__header">
        <span class="form-section__icon"><el-icon><DocumentCopy /></el-icon></span>
        <div>
          <h3>Attachment</h3>
          <p>Optional PDF or document for students to download.</p>
        </div>
      </header>

      <div class="form-section__body">
        <FileUploader kind="pdf" v-model="form.file_url" />
      </div>
    </section>

    <div class="form-actions">
      <el-button @click="goBack">Cancel</el-button>
      <el-button type="primary" :loading="saving" @click="handleSave">Save lesson</el-button>
    </div>
  </el-form>
</template>

<style scoped>
.lesson-form {
  max-width: 640px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-section {
  background: var(--surface-card);
  border: 1px solid var(--surface-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
  padding: 20px 22px;
}

.form-section__header {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  margin-bottom: 18px;
}

.form-section__icon {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 34px;
  height: 34px;
  border-radius: 9px;
  background: var(--brand-100);
  color: var(--brand-600);
  font-size: 16px;
}

.form-section__header h3 {
  margin: 0 0 2px;
  font-size: 15px;
  font-weight: 600;
}

.form-section__header p {
  margin: 0;
  font-size: 12.5px;
  color: var(--text-secondary);
}

.form-section__body {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.form-row--split {
  display: flex;
  gap: 16px;
  align-items: flex-start;
}

.form-row--grow {
  flex: 1;
}

.video-source-toggle {
  margin-bottom: 12px;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  padding: 4px 2px 24px;
}
</style>
