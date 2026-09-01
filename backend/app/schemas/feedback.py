from datetime import datetime

from pydantic import BaseModel, field_validator

from app.models.feedback import FeedbackStatus, FeedbackType


class FeedbackCreate(BaseModel):
    type: FeedbackType
    subject: str
    message: str

    @field_validator("subject")
    @classmethod
    def subject_not_blank(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Subject is required")
        return v.strip()

    @field_validator("message")
    @classmethod
    def message_not_blank(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Message is required")
        return v.strip()


class FeedbackOut(BaseModel):
    id: int
    type: FeedbackType
    subject: str
    message: str
    status: FeedbackStatus
    created_at: datetime


class FeedbackAdminOut(FeedbackOut):
    user_id: int
    user_full_name: str
    user_email: str


class FeedbackStatusUpdate(BaseModel):
    status: FeedbackStatus
