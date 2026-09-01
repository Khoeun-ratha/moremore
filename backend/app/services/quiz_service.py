from sqlalchemy.orm import Session, selectinload

from app.core.exceptions import AppError
from app.models.quiz import Question, Quiz, QuizAttempt, QuizAttemptAnswer
from app.schemas.quiz import AnswerResult, QuizResult, QuizSubmission
from app.services.progress_service import mark_lesson_complete


def get_quiz_with_questions(db: Session, quiz_id: int) -> Quiz:
    quiz = (
        db.query(Quiz)
        .options(selectinload(Quiz.questions).selectinload(Question.choices))
        .filter(Quiz.id == quiz_id)
        .first()
    )
    if quiz is None:
        raise AppError(404, "Quiz not found")
    return quiz


def submit_quiz(db: Session, user_id: int, quiz_id: int, submission: QuizSubmission) -> QuizResult:
    quiz = get_quiz_with_questions(db, quiz_id)

    if not quiz.questions:
        raise AppError(400, "Quiz has no questions")

    answers_by_question = {a.question_id: a.choice_id for a in submission.answers}

    results: list[AnswerResult] = []
    score = 0

    for question in quiz.questions:
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

    total = len(quiz.questions)
    percentage = round((score / total) * 100, 2)
    passed = percentage >= quiz.passing_score

    attempt = QuizAttempt(user_id=user_id, quiz_id=quiz.id, score=score, total=total, passed=passed)
    db.add(attempt)
    db.flush()

    for result in results:
        db.add(
            QuizAttemptAnswer(
                attempt_id=attempt.id,
                question_id=result.question_id,
                selected_choice_id=result.selected_choice_id,
                is_correct=result.is_correct,
            )
        )

    db.commit()
    db.refresh(attempt)

    if passed:
        mark_lesson_complete(db, user_id=user_id, lesson_id=quiz.lesson_id)

    return QuizResult(
        attempt_id=attempt.id,
        score=score,
        total=total,
        percentage=percentage,
        passed=passed,
        submitted_at=attempt.submitted_at,
        answers=results,
    )


def get_attempt_detail(db: Session, user_id: int, attempt_id: int) -> QuizResult:
    attempt = (
        db.query(QuizAttempt)
        .options(selectinload(QuizAttempt.answers))
        .filter(QuizAttempt.id == attempt_id)
        .first()
    )
    if attempt is None or attempt.user_id != user_id:
        raise AppError(404, "Quiz attempt not found")

    quiz = get_quiz_with_questions(db, attempt.quiz_id)
    correct_choice_by_question = {
        question.id: next(c.id for c in question.choices if c.is_correct) for question in quiz.questions
    }

    answers = [
        AnswerResult(
            question_id=a.question_id,
            selected_choice_id=a.selected_choice_id,
            correct_choice_id=correct_choice_by_question[a.question_id],
            is_correct=a.is_correct,
        )
        for a in attempt.answers
    ]

    return QuizResult(
        attempt_id=attempt.id,
        score=attempt.score,
        total=attempt.total,
        percentage=round((attempt.score / attempt.total) * 100, 2),
        passed=attempt.passed,
        submitted_at=attempt.submitted_at,
        answers=answers,
    )
