from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session, selectinload

from app.core.dependencies import get_current_user, get_db, require_admin
from app.core.exceptions import AppError
from app.models.course import Lesson
from app.models.quiz import Choice, Question, Quiz, QuizAttempt
from app.models.user import User
from app.schemas.quiz import (
    QuizAttemptOut,
    QuizCreate,
    QuizOut,
    QuizOutWithAnswers,
    QuizResult,
    QuizSubmission,
)
from app.services.quiz_service import get_attempt_detail, get_quiz_with_questions, submit_quiz

router = APIRouter(tags=["quizzes"])


@router.get("/lessons/{lesson_id}/quiz", response_model=QuizOut)
def get_lesson_quiz(lesson_id: int, db: Session = Depends(get_db), _user: User = Depends(get_current_user)):
    quiz = (
        db.query(Quiz)
        .options(selectinload(Quiz.questions).selectinload(Question.choices))
        .filter(Quiz.lesson_id == lesson_id)
        .first()
    )
    if quiz is None:
        raise AppError(404, "This lesson has no quiz")
    return quiz


@router.get("/quizzes/{quiz_id}/full", response_model=QuizOutWithAnswers)
def get_quiz_with_answers(quiz_id: int, db: Session = Depends(get_db), _admin: User = Depends(require_admin)):
    """Admin-only view exposing which choice is correct, for pre-filling the edit form."""
    return get_quiz_with_questions(db, quiz_id)


@router.post("/lessons/{lesson_id}/quiz", response_model=QuizOut, status_code=201)
def create_lesson_quiz(
    lesson_id: int, data: QuizCreate, db: Session = Depends(get_db), _admin: User = Depends(require_admin)
):
    lesson = db.get(Lesson, lesson_id)
    if lesson is None:
        raise AppError(404, "Lesson not found")
    if lesson.quiz is not None:
        raise AppError(409, "This lesson already has a quiz")

    quiz = Quiz(lesson_id=lesson_id, title=data.title, passing_score=data.passing_score)
    db.add(quiz)
    db.flush()

    for q in data.questions:
        question = Question(quiz_id=quiz.id, text=q.text, order_index=q.order_index)
        db.add(question)
        db.flush()
        for c in q.choices:
            db.add(Choice(question_id=question.id, text=c.text, is_correct=c.is_correct))

    db.commit()
    return get_quiz_with_questions(db, quiz.id)


@router.patch("/quizzes/{quiz_id}", response_model=QuizOut)
def update_quiz(
    quiz_id: int, data: QuizCreate, db: Session = Depends(get_db), _admin: User = Depends(require_admin)
):
    """Full replace of a quiz's title/passing score/questions/choices."""
    quiz = get_quiz_with_questions(db, quiz_id)

    quiz.title = data.title
    quiz.passing_score = data.passing_score

    for question in list(quiz.questions):
        db.delete(question)
    db.flush()

    for q in data.questions:
        question = Question(quiz_id=quiz.id, text=q.text, order_index=q.order_index)
        db.add(question)
        db.flush()
        for c in q.choices:
            db.add(Choice(question_id=question.id, text=c.text, is_correct=c.is_correct))

    db.commit()
    return get_quiz_with_questions(db, quiz_id)


@router.delete("/quizzes/{quiz_id}", status_code=204)
def delete_quiz(quiz_id: int, db: Session = Depends(get_db), _admin: User = Depends(require_admin)):
    quiz = db.get(Quiz, quiz_id)
    if quiz is None:
        raise AppError(404, "Quiz not found")
    db.delete(quiz)
    db.commit()


@router.post("/quizzes/{quiz_id}/submit", response_model=QuizResult)
def submit_quiz_answers(
    quiz_id: int,
    submission: QuizSubmission,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return submit_quiz(db, user_id=user.id, quiz_id=quiz_id, submission=submission)


@router.get("/quizzes/{quiz_id}/attempts", response_model=list[QuizAttemptOut])
def quiz_attempt_history(
    quiz_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)
):
    return (
        db.query(QuizAttempt)
        .filter(QuizAttempt.quiz_id == quiz_id, QuizAttempt.user_id == user.id)
        .order_by(QuizAttempt.submitted_at.desc())
        .all()
    )


@router.get("/quizzes/attempts/{attempt_id}", response_model=QuizResult)
def quiz_attempt_detail(
    attempt_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)
):
    """Lets a learner review the full question-by-question detail of a past attempt."""
    return get_attempt_detail(db, user_id=user.id, attempt_id=attempt_id)
