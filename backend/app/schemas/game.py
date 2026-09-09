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
    # This round's current leaderboard rank — 1 if it's now the player's
    # (and the platform's) best-ever round. Null if leaderboard ranking
    # couldn't be computed (never expected in practice, right after a
    # successful submit).
    rank: int | None = None


class GameAttemptOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    course_id: int | None
    score: int
    total: int
    submitted_at: datetime


class GameAttemptAdminOut(BaseModel):
    """A game attempt with the submitting user's identity attached, for
    admin moderation/monitoring — never exposed to non-admin endpoints."""

    id: int
    user_id: int
    user_full_name: str
    user_email: str
    course_id: int | None
    course_title: str | None
    score: int
    total: int
    percentage: float
    submitted_at: datetime


class LeaderboardEntryOut(BaseModel):
    """A player's single best Quick Challenge round, ranked by score
    percentage (ties broken by raw score, then who got there first)."""

    rank: int
    user_id: int
    full_name: str
    score: int
    total: int
    percentage: float
    achieved_at: datetime
