from datetime import datetime

from pydantic import BaseModel, field_validator


class ReviewCreate(BaseModel):
    rating: int
    comment: str = ""

    @field_validator("rating")
    @classmethod
    def rating_in_range(cls, v: int) -> int:
        if not 1 <= v <= 5:
            raise ValueError("Rating must be between 1 and 5")
        return v


class ReviewOut(BaseModel):
    id: int
    course_id: int
    user_id: int
    reviewer_name: str
    rating: int
    comment: str
    created_at: datetime
