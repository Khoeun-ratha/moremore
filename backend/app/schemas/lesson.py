from datetime import datetime

from pydantic import BaseModel, ConfigDict


class LessonCreate(BaseModel):
    title: str
    order_index: int = 0
    content: str = ""
    video_url: str | None = None
    file_url: str | None = None


class LessonUpdate(BaseModel):
    title: str | None = None
    order_index: int | None = None
    content: str | None = None
    video_url: str | None = None
    file_url: str | None = None


class LessonOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    course_id: int
    title: str
    order_index: int
    content: str
    video_url: str | None
    file_url: str | None
    created_at: datetime
    has_quiz: bool = False
    completed: bool = False
