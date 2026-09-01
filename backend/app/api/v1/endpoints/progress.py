from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user, get_db
from app.models.user import User
from app.schemas.progress import CourseProgressOut, OverallProgressOut
from app.services.progress_service import get_course_progress, get_overall_progress

router = APIRouter(prefix="/progress", tags=["progress"])


@router.get("/me", response_model=OverallProgressOut)
def my_progress(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return get_overall_progress(db, user.id)


@router.get("/courses/{course_id}", response_model=CourseProgressOut)
def my_course_progress(course_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return get_course_progress(db, user.id, course_id)
