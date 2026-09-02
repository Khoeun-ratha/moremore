import random

from sqlalchemy.orm import Session, selectinload

from app.core.exceptions import AppError
from app.models.course import Lesson
from app.models.game import GameAttempt
from app.models.quiz import Question, Quiz
from app.schemas.game import GameResult, GameSubmission
from app.schemas.quiz import AnswerResult


def get_random_questions(db: Session, course_id: int | None, count: int) -> list[Question]:
    query = (
        db.query(Question)
        .join(Quiz, Question.quiz_id == Quiz.id)
        .options(selectinload(Question.choices))
    )
    if course_id is not None:
        query = query.join(Lesson, Quiz.lesson_id == Lesson.id).filter(Lesson.course_id == course_id)

    all_questions = query.all()
    if not all_questions:
        detail = "No quiz questions available for this course yet" if course_id else "No quiz questions available yet"
        raise AppError(404, detail)

    k = min(count, len(all_questions))
    return random.sample(all_questions, k)


def submit_game(db: Session, user_id: int, course_id: int | None, submission: GameSubmission) -> GameResult:
    if not submission.answers:
        raise AppError(400, "Submit at least one answer")

    question_ids = [a.question_id for a in submission.answers]
    questions = (
        db.query(Question)
        .options(selectinload(Question.choices))
        .filter(Question.id.in_(question_ids))
        .all()
    )
    questions_by_id = {q.id: q for q in questions}
    if len(questions_by_id) != len(set(question_ids)):
        raise AppError(400, "One or more questions are invalid")

    answers_by_question = {a.question_id: a.choice_id for a in submission.answers}

    results: list[AnswerResult] = []
    score = 0
    for question_id in question_ids:
        question = questions_by_id[question_id]
        correct_choice = next((c for c in question.choices if c.is_correct), None)
        if correct_choice is None:
            raise AppError(500, f"Question {question.id} has no correct choice configured")

        selected_choice_id = answers_by_question.get(question.id)
        valid_choice_ids = {c.id for c in question.choices}
        if selected_choice_id is not None and selected_choice_id not in valid_choice_ids:
            raise AppError(400, f"Choice {selected_choice_id} does not belong to question {question.id}")

        is_correct = selected_choice_id == correct_choice.id
        if is_correct:
            score += 1

        results.append(
            AnswerResult(
                question_id=question.id,
                selected_choice_id=selected_choice_id,
                correct_choice_id=correct_choice.id,
                is_correct=is_correct,
            )
        )

    total = len(results)
    percentage = round((score / total) * 100, 2)

    attempt = GameAttempt(user_id=user_id, course_id=course_id, score=score, total=total)
    db.add(attempt)
    db.commit()
    db.refresh(attempt)

    return GameResult(
        score=score,
        total=total,
        percentage=percentage,
        submitted_at=attempt.submitted_at,
        answers=results,
    )
