import { reactive } from 'vue'
import type { QuizCreate, QuizWithAnswers } from '../types/api'

let keyCounter = 0
function nextKey(): string {
  keyCounter += 1
  return `k${keyCounter}`
}

export interface ChoiceForm {
  _key: string
  text: string
}

export interface QuestionForm {
  _key: string
  text: string
  order_index: number
  choices: ChoiceForm[]
  correctKey: string | null
}

export interface QuizForm {
  title: string
  passing_score: number
  questions: QuestionForm[]
}

function emptyChoice(): ChoiceForm {
  return { _key: nextKey(), text: '' }
}

function emptyQuestion(orderIndex: number): QuestionForm {
  const a = emptyChoice()
  const b = emptyChoice()
  return {
    _key: nextKey(),
    text: '',
    order_index: orderIndex,
    choices: [a, b],
    correctKey: a._key,
  }
}

export function useQuizForm() {
  const form = reactive<QuizForm>({
    title: '',
    passing_score: 70,
    questions: [emptyQuestion(1)],
  })

  function addQuestion() {
    form.questions.push(emptyQuestion(form.questions.length + 1))
  }

  function removeQuestion(key: string) {
    form.questions = form.questions.filter((q) => q._key !== key)
  }

  function addChoice(questionKey: string) {
    const question = form.questions.find((q) => q._key === questionKey)
    if (question) question.choices.push(emptyChoice())
  }

  function removeChoice(questionKey: string, choiceKey: string) {
    const question = form.questions.find((q) => q._key === questionKey)
    if (!question) return
    question.choices = question.choices.filter((c) => c._key !== choiceKey)
    if (question.correctKey === choiceKey) {
      question.correctKey = question.choices[0]?._key ?? null
    }
  }

  function loadFromApi(quiz: QuizWithAnswers) {
    form.title = quiz.title
    form.passing_score = quiz.passing_score
    form.questions = quiz.questions
      .slice()
      .sort((a, b) => a.order_index - b.order_index)
      .map((q) => {
        const choices = q.choices.map((c) => ({ _key: nextKey(), text: c.text, _correct: c.is_correct }))
        return {
          _key: nextKey(),
          text: q.text,
          order_index: q.order_index,
          choices: choices.map(({ _key, text }) => ({ _key, text })),
          correctKey: choices.find((c) => c._correct)?._key ?? null,
        }
      })
  }

  function validate(): string[] {
    const errors: string[] = []
    if (!form.title.trim()) errors.push('Quiz title is required.')
    if (form.questions.length === 0) errors.push('A quiz needs at least one question.')

    form.questions.forEach((q, i) => {
      const label = `Question ${i + 1}`
      if (!q.text.trim()) errors.push(`${label}: text is required.`)
      if (q.choices.length < 2) errors.push(`${label}: needs at least two choices.`)
      if (q.choices.some((c) => !c.text.trim())) errors.push(`${label}: all choices need text.`)
      if (!q.correctKey || !q.choices.some((c) => c._key === q.correctKey)) {
        errors.push(`${label}: must have exactly one correct choice selected.`)
      }
    })

    return errors
  }

  function toPayload(): QuizCreate {
    return {
      title: form.title,
      passing_score: form.passing_score,
      questions: form.questions.map((q, i) => ({
        text: q.text,
        order_index: q.order_index ?? i + 1,
        choices: q.choices.map((c) => ({ text: c.text, is_correct: c._key === q.correctKey })),
      })),
    }
  }

  return { form, addQuestion, removeQuestion, addChoice, removeChoice, loadFromApi, validate, toPayload }
}
