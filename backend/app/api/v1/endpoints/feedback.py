from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user, get_db, require_admin
from app.models.feedback import Feedback, FeedbackStatus, FeedbackType
from app.models.user import User
from app.schemas.common import Page
from app.schemas.feedback import FeedbackAdminOut, FeedbackCreate, FeedbackOut, FeedbackStatusUpdate
from app.services.feedback_service import (
    create_feedback,
    get_feedback,
    list_feedback,
    list_my_feedback,
    update_feedback_status,
)

router = APIRouter(prefix="/feedback", tags=["feedback"])


def _to_admin_out(f: Feedback) -> FeedbackAdminOut:
    return FeedbackAdminOut(
        id=f.id,
        type=f.type,
        subject=f.subject,
        message=f.message,
        status=f.status,
        created_at=f.created_at,
        user_id=f.user_id,
        user_full_name=f.user.full_name,
        user_email=f.user.email,
    )


@router.post("", response_model=FeedbackOut, status_code=201)
def submit_feedback(data: FeedbackCreate, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return create_feedback(db, user_id=user.id, type=data.type, subject=data.subject, message=data.message)


@router.get("/me", response_model=list[FeedbackOut])
def my_feedback(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return list_my_feedback(db, user.id)


@router.get("", response_model=Page)
def list_all_feedback(
    q: str | None = Query(None, description="Search by subject, message, submitter name, or email"),
    type: FeedbackType | None = None,
    status: FeedbackStatus | None = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    items, total = list_feedback(db, q=q, type=type, status=status, page=page, page_size=page_size)
    return Page(items=[_to_admin_out(f) for f in items], total=total, page=page, page_size=page_size)


@router.get("/{feedback_id}", response_model=FeedbackAdminOut)
def get_one_feedback(feedback_id: int, db: Session = Depends(get_db), _admin: User = Depends(require_admin)):
    return _to_admin_out(get_feedback(db, feedback_id))


@router.patch("/{feedback_id}", response_model=FeedbackAdminOut)
def update_status(
    feedback_id: int,
    data: FeedbackStatusUpdate,
    db: Session = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    return _to_admin_out(update_feedback_status(db, feedback_id, data.status))
