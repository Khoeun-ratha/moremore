import random

from sqlalchemy.orm import Session, selectinload

from app.core.exceptions import AppError
from app.models.course import Course, Lesson
from app.models.game import GameAttempt
from app.models.quiz import Question, Quiz
from app.models.user import User
from app.schemas.game import GameAttemptAdminOut, GameResult, GameSubmission, LeaderboardEntryOut
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

    rank = None
    for entry in _rank_all_players(db):
        if entry.user_id == user_id:
            rank = entry.rank
            break

    return GameResult(
        score=score,
        total=total,
        percentage=percentage,
        submitted_at=attempt.submitted_at,
        answers=results,
        rank=rank,
    )


def _rank_all_players(db: Session) -> list[LeaderboardEntryOut]:
    """Every player's single best Quick Challenge round, ranked by score
    percentage — ties broken by the higher raw score, then whoever set it
    first. Computed in Python: attempt volume is small enough that a plain
    scan is simpler and clearer than a SQL ratio comparison."""
    attempts = (
        db.query(GameAttempt, User)
        .join(User, User.id == GameAttempt.user_id)
        .filter(GameAttempt.total > 0)
        .all()
    )

    best_by_user: dict[int, tuple[GameAttempt, User]] = {}
    for attempt, user in attempts:
        current = best_by_user.get(user.id)
        if current is None:
            best_by_user[user.id] = (attempt, user)
            continue
        current_attempt, _ = current
        current_pct = current_attempt.score / current_attempt.total
        candidate_pct = attempt.score / attempt.total
        better = (
            candidate_pct > current_pct
            or (candidate_pct == current_pct and attempt.score > current_attempt.score)
            or (
                candidate_pct == current_pct
                and attempt.score == current_attempt.score
                and attempt.submitted_at < current_attempt.submitted_at
            )
        )
        if better:
            best_by_user[user.id] = (attempt, user)

    ranked = sorted(
        best_by_user.values(),
        key=lambda pair: (-(pair[0].score / pair[0].total), -pair[0].score, pair[0].submitted_at),
    )

    return [
        LeaderboardEntryOut(
            rank=i + 1,
            user_id=user.id,
            full_name=user.full_name,
            score=attempt.score,
            total=attempt.total,
            percentage=round((attempt.score / attempt.total) * 100, 2),
            achieved_at=attempt.submitted_at,
        )
        for i, (attempt, user) in enumerate(ranked)
    ]


def get_leaderboard(db: Session, limit: int = 20) -> list[LeaderboardEntryOut]:
    return _rank_all_players(db)[:limit]


def list_game_attempts_admin(
    db: Session, page: int = 1, page_size: int = 20, q: str | None = None
) -> tuple[list[GameAttemptAdminOut], int]:
    """Every game attempt platform-wide, newest first — for admin
    monitoring/moderation. Optional `q` filters by submitting user's name
    or email."""
    query = (
        db.query(GameAttempt, User, Course)
        .join(User, User.id == GameAttempt.user_id)
        .outerjoin(Course, Course.id == GameAttempt.course_id)
    )
    if q:
        like = f"%{q}%"
        query = query.filter((User.full_name.ilike(like)) | (User.email.ilike(like)))

    total = query.count()
    rows = (
        query.order_by(GameAttempt.submitted_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )

    items = [
        GameAttemptAdminOut(
            id=attempt.id,
            user_id=user.id,
            user_full_name=user.full_name,
            user_email=user.email,
            course_id=attempt.course_id,
            course_title=course.title if course else None,
            score=attempt.score,
            total=attempt.total,
            percentage=round((attempt.score / attempt.total) * 100, 2) if attempt.total else 0.0,
            submitted_at=attempt.submitted_at,
        )
        for attempt, user, course in rows
    ]
    return items, total


def delete_game_attempt_admin(db: Session, attempt_id: int) -> None:
    attempt = db.get(GameAttempt, attempt_id)
    if attempt is None:
        raise AppError(404, "Game attempt not found")
    db.delete(attempt)
    db.commit()
