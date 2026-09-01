from datetime import datetime

from pydantic import BaseModel, ConfigDict, field_validator


class ChoiceCreate(BaseModel):
    text: str
    is_correct: bool = False


class QuestionCreate(BaseModel):
    text: str
    order_index: int = 0
    choices: list[ChoiceCreate]

    @field_validator("choices")
    @classmethod
    def must_have_one_correct_choice(cls, choices: list[ChoiceCreate]) -> list[ChoiceCreate]:
        if len(choices) < 2:
            raise ValueError("Each question needs at least two choices")
        if sum(1 for c in choices if c.is_correct) != 1:
            raise ValueError("Each question must have exactly one correct choice")
        return choices


class QuizCreate(BaseModel):
    title: str
    passing_score: int = 70
    questions: list[QuestionCreate]

    @field_validator("questions")
    @classmethod
    def must_have_questions(cls, questions: list[QuestionCreate]) -> list[QuestionCreate]:
        if not questions:
            raise ValueError("A quiz needs at least one question")
        return questions


class ChoiceOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    text: str


class ChoiceOutWithAnswer(ChoiceOut):
    is_correct: bool


class QuestionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    text: str
    order_index: int
    choices: list[ChoiceOut]


class QuizOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    lesson_id: int
    title: str
    passing_score: int
    questions: list[QuestionOut]


class QuestionOutWithAnswers(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    text: str
    order_index: int
    choices: list[ChoiceOutWithAnswer]


class QuizOutWithAnswers(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    lesson_id: int
    title: str
    passing_score: int
    questions: list[QuestionOutWithAnswers]


class AnswerSubmission(BaseModel):
    question_id: int
    choice_id: int


class QuizSubmission(BaseModel):
    answers: list[AnswerSubmission]


class AnswerResult(BaseModel):
    question_id: int
    selected_choice_id: int | None
    correct_choice_id: int
    is_correct: bool


class QuizResult(BaseModel):
    attempt_id: int
    score: int
    total: int
    percentage: float
    passed: bool
    submitted_at: datetime
    answers: list[AnswerResult]


class QuizAttemptOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    quiz_id: int
    score: int
    total: int
    passed: bool
    submitted_at: datetime
