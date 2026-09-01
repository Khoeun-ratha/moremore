from sqlalchemy import func
from sqlalchemy.orm import Session, selectinload

from app.core.exceptions import AppError
from app.models.course import Course
from app.models.review import CourseReview


def list_reviews(db: Session, course_id: int) -> list[CourseReview]:
    return (
        db.query(CourseReview)
        .options(selectinload(CourseReview.user))
        .filter(CourseReview.course_id == course_id)
        .order_by(CourseReview.created_at.desc())
        .all()
    )


def upsert_review(db: Session, course_id: int, user_id: int, rating: int, comment: str) -> CourseReview:
    course = db.get(Course, course_id)
    if course is None:
        raise AppError(404, "Course not found")

    review = (
        db.query(CourseReview)
        .filter(CourseReview.course_id == course_id, CourseReview.user_id == user_id)
        .first()
    )
    if review is None:
        review = CourseReview(course_id=course_id, user_id=user_id, rating=rating, comment=comment)
        db.add(review)
    else:
        review.rating = rating
        review.comment = comment

    db.commit()
    db.refresh(review)
    return review


def get_rating_map(db: Session, course_ids: list[int]) -> dict[int, tuple[float, int]]:
    """Maps course_id -> (average_rating, review_count) for the given courses."""
    if not course_ids:
        return {}

    rows = (
        db.query(CourseReview.course_id, func.avg(CourseReview.rating), func.count(CourseReview.id))
        .filter(CourseReview.course_id.in_(course_ids))
        .group_by(CourseReview.course_id)
        .all()
    )
    return {course_id: (round(float(avg), 2), count) for course_id, avg, count in rows}
