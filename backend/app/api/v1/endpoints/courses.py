from fastapi import APIRouter, Depends, Query
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user, get_db, require_admin
from app.core.exceptions import AppError
from app.models.course import Course
from app.models.user import User
from app.schemas.common import Page
from app.schemas.course import CourseCreate, CourseDetailOut, CourseOut, CourseUpdate
from app.services.recommendation_service import get_recommendations
from app.services.review_service import get_rating_map

router = APIRouter(prefix="/courses", tags=["courses"])


def _with_rating(course: Course, ratings: dict[int, tuple[float, int]]) -> CourseOut:
    avg, count = ratings.get(course.id, (None, 0))
    return CourseOut.model_validate(course).model_copy(update={"average_rating": avg, "review_count": count})


@router.get("", response_model=Page)
def list_courses(
    q: str | None = Query(None, description="Search text against title/description"),
    category: str | None = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    _user: User = Depends(get_current_user),
):
    query = db.query(Course)
    if q:
        like = f"%{q}%"
        query = query.filter(or_(Course.title.ilike(like), Course.description.ilike(like)))
    if category:
        query = query.filter(Course.category == category)

    total = query.count()
    items = query.order_by(Course.created_at.desc()).offset((page - 1) * page_size).limit(page_size).all()

    ratings = get_rating_map(db, [c.id for c in items])
    return Page(items=[_with_rating(c, ratings) for c in items], total=total, page=page, page_size=page_size)


@router.get("/recommended", response_model=list[CourseOut])
def recommended_courses(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    courses = get_recommendations(db, user.id)
    ratings = get_rating_map(db, [c.id for c in courses])
    return [_with_rating(c, ratings) for c in courses]


@router.post("", response_model=CourseOut, status_code=201)
def create_course(data: CourseCreate, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    course = Course(**data.model_dump(), created_by=admin.id)
    db.add(course)
    db.commit()
    db.refresh(course)
    return course


@router.get("/{course_id}", response_model=CourseDetailOut)
def get_course(course_id: int, db: Session = Depends(get_db), _user: User = Depends(get_current_user)):
    course = db.get(Course, course_id)
    if course is None:
        raise AppError(404, "Course not found")
    ratings = get_rating_map(db, [course.id])
    data = _with_rating(course, ratings).model_dump()
    return CourseDetailOut(**data, lesson_count=len(course.lessons))


@router.patch("/{course_id}", response_model=CourseOut)
def update_course(
    course_id: int, data: CourseUpdate, db: Session = Depends(get_db), _admin: User = Depends(require_admin)
):
    course = db.get(Course, course_id)
    if course is None:
        raise AppError(404, "Course not found")

    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(course, field, value)

    db.commit()
    db.refresh(course)
    return course


@router.delete("/{course_id}", status_code=204)
def delete_course(course_id: int, db: Session = Depends(get_db), _admin: User = Depends(require_admin)):
    course = db.get(Course, course_id)
    if course is None:
        raise AppError(404, "Course not found")
    db.delete(course)
    db.commit()
