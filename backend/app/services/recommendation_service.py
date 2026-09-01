"""Extension point for future AI-driven recommendations and adaptive quizzes.

Current implementation is a naive heuristic: courses in categories the user
has already engaged with (via lesson progress), ranked by overall popularity,
excluding courses the user has already completed. Swap the body of
`get_recommendations` for a model-backed ranking later without touching callers.
"""

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.course import Course, Lesson
from app.models.progress import LessonProgress


def get_recommendations(db: Session, user_id: int, limit: int = 5) -> list[Course]:
    engaged_categories = (
        db.query(Course.category)
        .join(Lesson, Lesson.course_id == Course.id)
        .join(LessonProgress, LessonProgress.lesson_id == Lesson.id)
        .filter(LessonProgress.user_id == user_id)
        .distinct()
        .all()
    )
    categories = [c[0] for c in engaged_categories]

    completed_course_ids = (
        db.query(Course.id)
        .join(Lesson, Lesson.course_id == Course.id)
        .join(LessonProgress, LessonProgress.lesson_id == Lesson.id)
        .filter(LessonProgress.user_id == user_id)
        .group_by(Course.id)
        .having(func.count(Lesson.id.distinct()) == func.count(LessonProgress.id))
        .all()
    )
    completed_ids = {c[0] for c in completed_course_ids}

    query = db.query(Course)
    if categories:
        query = query.filter(Course.category.in_(categories))
    if completed_ids:
        query = query.filter(~Course.id.in_(completed_ids))

    return query.order_by(Course.created_at.desc()).limit(limit).all()
