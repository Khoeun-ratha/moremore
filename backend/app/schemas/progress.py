from datetime import datetime

from pydantic import BaseModel


class LessonProgressOut(BaseModel):
    lesson_id: int
    completed: bool
    completed_at: datetime | None


class CourseProgressOut(BaseModel):
    course_id: int
    course_title: str
    total_lessons: int
    completed_lessons: int
    percentage: float
    certificate_number: str | None = None


class OverallProgressOut(BaseModel):
    courses: list[CourseProgressOut]
    overall_percentage: float
