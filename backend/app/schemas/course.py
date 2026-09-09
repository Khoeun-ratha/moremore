from datetime import datetime

from pydantic import BaseModel, ConfigDict, field_validator


class CourseCreate(BaseModel):
    title: str
    description: str = ""
    category: str = ""
    level: str = "beginner"
    cover_image_url: str | None = None

    @field_validator("title")
    @classmethod
    def title_not_blank(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Title is required")
        return v.strip()


class CourseUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    category: str | None = None
    level: str | None = None
    cover_image_url: str | None = None


class CourseOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    description: str
    category: str
    level: str
    cover_image_url: str | None
    created_by: int
    created_at: datetime
    updated_at: datetime
    average_rating: float | None = None
    review_count: int = 0


class CourseDetailOut(CourseOut):
    lesson_count: int
