from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.schemas.quiz import AnswerResult, AnswerSubmission, ChoiceOutWithAnswer


class GameQuestionOut(BaseModel):
    """Unlike a lesson quiz, the game reveals is_correct on every choice up
    front — it's a casual practice mode (instant right/wrong feedback per
    question), not a graded assessment, so there's nothing to protect."""

    model_config = ConfigDict(from_attributes=True)
    id: int
    text: str
    choices: list[ChoiceOutWithAnswer]


class GameSubmission(BaseModel):
    answers: list[AnswerSubmission]


class GameResult(BaseModel):
    score: int
    total: int
    percentage: float
    submitted_at: datetime
    answers: list[AnswerResult]


class GameAttemptOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    course_id: int | None
    score: int
    total: int
    submitted_at: datetime
