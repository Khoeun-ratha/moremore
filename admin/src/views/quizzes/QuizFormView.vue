<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { ArrowLeft, Delete, Plus } from '@element-plus/icons-vue'
import { createLessonQuiz, getLessonQuiz, getQuizWithAnswers, updateQuiz } from '../../api/quizzes'
import { getLesson } from '../../api/lessons'
import { useQuizForm } from '../../composables/useQuizForm'

const props = defineProps<{ lessonId: number }>()
const router = useRouter()

const { form, addQuestion, removeQuestion, addChoice, removeChoice, loadFromApi, validate, toPayload } =
  useQuizForm()

const courseId = ref<number | null>(null)
const quizId = ref<number | null>(null)
const loading = ref(true)
const saving = ref(false)

onMounted(async () => {
  try {
    const lesson = await getLesson(props.lessonId)
    courseId.value = lesson.course_id

    if (lesson.has_quiz) {
      const quiz = await getLessonQuiz(props.lessonId)
      quizId.value = quiz.id
      const withAnswers = await getQuizWithAnswers(quiz.id)
      loadFromApi(withAnswers)
    }
  } finally {
    loading.value = false
  }
})

function goBack() {
  router.push({ name: 'course-detail', params: { id: courseId.value } })
}

async function handleSave() {
  const errors = validate()
  if (errors.length) {
    ElMessage.error(errors[0])
    return
  }

  saving.value = true
  try {
    const payload = toPayload()
    if (quizId.value) {
      await updateQuiz(quizId.value, payload)
      ElMessage.success('Quiz updated')
    } else {
      await createLessonQuiz(props.lessonId, payload)
      ElMessage.success('Quiz created')
    }
    goBack()
  } catch {
    ElMessage.error('Could not save the quiz. Check that every question has exactly one correct choice.')
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <el-button text :icon="ArrowLeft" class="back-link" @click="goBack">Back to course</el-button>

  <div class="page-header">
    <div>
      <h2>{{ quizId ? 'Edit quiz' : 'New quiz' }}</h2>
      <p>Build the questions and choices learners will answer for this lesson.</p>
    </div>
  </div>

  <div v-loading="loading" style="max-width: 720px">
    <div class="surface-card" style="margin-bottom: 16px">
      <el-form label-position="top">
        <el-form-item label="Quiz title">
          <el-input v-model="form.title" />
        </el-form-item>
        <el-form-item label="Passing score (%)">
          <el-input-number v-model="form.passing_score" :min="0" :max="100" />
        </el-form-item>
      </el-form>
    </div>

    <el-card v-for="(question, qIndex) in form.questions" :key="question._key" style="margin-bottom: 16px">
      <template #header>
        <div style="display: flex; align-items: center">
          <span style="font-weight: 600">Question {{ qIndex + 1 }}</span>
          <el-button
            text
            type="danger"
            :icon="Delete"
            style="margin-left: auto"
            :disabled="form.questions.length <= 1"
            @click="removeQuestion(question._key)"
          >
            Remove question
          </el-button>
        </div>
      </template>

      <el-input v-model="question.text" placeholder="Question text" style="margin-bottom: 12px" />

      <el-radio-group v-model="question.correctKey" style="display: flex; flex-direction: column; gap: 8px; width: 100%">
        <div v-for="choice in question.choices" :key="choice._key" style="display: flex; align-items: center; gap: 8px">
          <el-radio :value="choice._key" />
          <el-input v-model="choice.text" placeholder="Choice text" />
          <el-button
            text
            type="danger"
            :icon="Delete"
            circle
            :disabled="question.choices.length <= 2"
            @click="removeChoice(question._key, choice._key)"
          />
        </div>
      </el-radio-group>

      <el-button text :icon="Plus" style="margin-top: 8px" @click="addChoice(question._key)">Add choice</el-button>
    </el-card>

    <el-button :icon="Plus" @click="addQuestion">Add question</el-button>

    <div style="margin-top: 24px">
      <el-button type="primary" :loading="saving" @click="handleSave">Save quiz</el-button>
    </div>
  </div>
</template>
