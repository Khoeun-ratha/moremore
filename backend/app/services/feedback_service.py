from sqlalchemy import or_
from sqlalchemy.orm import Session, selectinload

from app.core.exceptions import AppError
from app.models.feedback import Feedback, FeedbackStatus, FeedbackType
from app.models.user import User


def create_feedback(db: Session, user_id: int, type: FeedbackType, subject: str, message: str) -> Feedback:
    feedback = Feedback(user_id=user_id, type=type, subject=subject, message=message)
    db.add(feedback)
    db.commit()
    db.refresh(feedback)
    return feedback


def list_my_feedback(db: Session, user_id: int) -> list[Feedback]:
    return (
        db.query(Feedback)
        .filter(Feedback.user_id == user_id)
        .order_by(Feedback.created_at.desc())
        .all()
    )


def list_feedback(
    db: Session,
    q: str | None = None,
    type: FeedbackType | None = None,
    status: FeedbackStatus | None = None,
    page: int = 1,
    page_size: int = 20,
) -> tuple[list[Feedback], int]:
    query = (
        db.query(Feedback)
        .join(User, Feedback.user_id == User.id)
        .options(selectinload(Feedback.user))
    )
    if type is not None:
        query = query.filter(Feedback.type == type)
    if status is not None:
        query = query.filter(Feedback.status == status)
    if q:
        like = f"%{q}%"
        query = query.filter(
            or_(
                Feedback.subject.ilike(like),
                Feedback.message.ilike(like),
                User.full_name.ilike(like),
                User.email.ilike(like),
            )
        )

    total = query.count()
    items = query.order_by(Feedback.created_at.desc()).offset((page - 1) * page_size).limit(page_size).all()
    return items, total


def get_feedback(db: Session, feedback_id: int) -> Feedback:
    feedback = (
        db.query(Feedback)
        .options(selectinload(Feedback.user))
        .filter(Feedback.id == feedback_id)
        .first()
    )
    if feedback is None:
        raise AppError(404, "Feedback not found")
    return feedback


def update_feedback_status(db: Session, feedback_id: int, status: FeedbackStatus) -> Feedback:
    feedback = get_feedback(db, feedback_id)
    feedback.status = status
    db.commit()
    db.refresh(feedback)
    return feedback
