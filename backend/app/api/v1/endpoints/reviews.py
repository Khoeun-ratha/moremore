from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user, get_db
from app.models.user import User
from app.schemas.review import ReviewCreate, ReviewOut
from app.services.review_service import list_reviews, upsert_review

router = APIRouter(tags=["reviews"])


def _to_review_out(review) -> ReviewOut:
    return ReviewOut(
        id=review.id,
        course_id=review.course_id,
        user_id=review.user_id,
        reviewer_name=review.user.full_name,
        rating=review.rating,
        comment=review.comment,
        created_at=review.created_at,
    )


@router.get("/courses/{course_id}/reviews", response_model=list[ReviewOut])
def get_course_reviews(course_id: int, db: Session = Depends(get_db), _user: User = Depends(get_current_user)):
    return [_to_review_out(r) for r in list_reviews(db, course_id)]


@router.put("/courses/{course_id}/reviews/me", response_model=ReviewOut)
def put_my_review(
    course_id: int, data: ReviewCreate, db: Session = Depends(get_db), user: User = Depends(get_current_user)
):
    review = upsert_review(db, course_id=course_id, user_id=user.id, rating=data.rating, comment=data.comment)
    return _to_review_out(review)
