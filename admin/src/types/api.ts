export type UserRole = 'user' | 'admin'

export interface User {
  id: number
  email: string
  full_name: string
  role: UserRole
  is_active: boolean
  created_at: string
}

export interface TokenPair {
  access_token: string
  refresh_token: string
  token_type: string
}

export interface Page<T> {
  items: T[]
  total: number
  page: number
  page_size: number
}

export interface Course {
  id: number
  title: string
  description: string
  category: string
  level: string
  cover_image_url: string | null
  created_by: number
  created_at: string
  updated_at: string
}

export interface CourseDetail extends Course {
  lesson_count: number
}

export interface Lesson {
  id: number
  course_id: number
  title: string
  order_index: number
  content: string
  video_url: string | null
  file_url: string | null
  created_at: string
  has_quiz: boolean
}

export interface Choice {
  id: number
  text: string
}

export interface ChoiceWithAnswer extends Choice {
  is_correct: boolean
}

export interface Question {
  id: number
  text: string
  order_index: number
  choices: Choice[]
}

export interface QuestionWithAnswers {
  id: number
  text: string
  order_index: number
  choices: ChoiceWithAnswer[]
}

export interface Quiz {
  id: number
  lesson_id: number
  title: string
  passing_score: number
  questions: Question[]
}

export interface QuizWithAnswers {
  id: number
  lesson_id: number
  title: string
  passing_score: number
  questions: QuestionWithAnswers[]
}

export interface ChoiceCreate {
  text: string
  is_correct: boolean
}

export interface QuestionCreate {
  text: string
  order_index: number
  choices: ChoiceCreate[]
}

export interface QuizCreate {
  title: string
  passing_score: number
  questions: QuestionCreate[]
}

export interface CourseProgress {
  course_id: number
  course_title: string
  total_lessons: number
  completed_lessons: number
  percentage: number
  certificate_number: string | null
}

export interface OverallProgress {
  courses: CourseProgress[]
  overall_percentage: number
}

export interface Certificate {
  id: number
  course_id: number
  course_title: string
  user_id: number
  user_full_name: string
  user_email: string
  certificate_number: string
  issued_at: string
}

export interface FileUploadResult {
  url: string
  filename: string
  kind: string
  size_bytes: number
}

export type FeedbackType = 'feedback' | 'lesson_suggestion'
export type FeedbackStatus = 'new' | 'reviewed' | 'dismissed'

export interface Feedback {
  id: number
  type: FeedbackType
  subject: string
  message: string
  status: FeedbackStatus
  created_at: string
  user_id: number
  user_full_name: string
  user_email: string
}

export interface ApiErrorBody {
  error?: string
  detail?: unknown
}
