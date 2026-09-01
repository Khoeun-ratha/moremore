from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user, get_db, require_admin
from app.core.exceptions import AppError
from app.models.course import Course, Lesson
from app.models.progress import LessonProgress
from app.models.user import User
from app.schemas.lesson import LessonCreate, LessonOut, LessonUpdate
from app.services.progress_service import mark_lesson_complete

router = APIRouter(tags=["lessons"])


def _to_lesson_out(lesson: Lesson, completed: bool = False) -> LessonOut:
    return LessonOut(
        id=lesson.id,
        course_id=lesson.course_id,
        title=lesson.title,
        order_index=lesson.order_index,
        content=lesson.content,
        video_url=lesson.video_url,
        file_url=lesson.file_url,
        created_at=lesson.created_at,
        has_quiz=lesson.quiz is not None,
        completed=completed,
    )


@router.get("/courses/{course_id}/lessons", response_model=list[LessonOut])
def list_lessons(course_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    course = db.get(Course, course_id)
    if course is None:
        raise AppError(404, "Course not found")

    lesson_ids = [lesson.id for lesson in course.lessons]
    completed_ids = {
        lp.lesson_id
        for lp in db.query(LessonProgress).filter(
            LessonProgress.user_id == user.id,
            LessonProgress.lesson_id.in_(lesson_ids),
            LessonProgress.completed.is_(True),
        )
    } if lesson_ids else set()

    return [_to_lesson_out(lesson, completed=lesson.id in completed_ids) for lesson in course.lessons]


@router.post("/courses/{course_id}/lessons", response_model=LessonOut, status_code=201)
def create_lesson(
    course_id: int, data: LessonCreate, db: Session = Depends(get_db), _admin: User = Depends(require_admin)
):
    course = db.get(Course, course_id)
    if course is None:
        raise AppError(404, "Course not found")

    lesson = Lesson(course_id=course_id, **data.model_dump())
    db.add(lesson)
    db.commit()
    db.refresh(lesson)
    return _to_lesson_out(lesson)


@router.get("/lessons/{lesson_id}", response_model=LessonOut)
def get_lesson(lesson_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    lesson = db.get(Lesson, lesson_id)
    if lesson is None:
        raise AppError(404, "Lesson not found")

    progress = (
        db.query(LessonProgress)
        .filter(LessonProgress.user_id == user.id, LessonProgress.lesson_id == lesson_id)
        .first()
    )
    return _to_lesson_out(lesson, completed=bool(progress and progress.completed))


@router.post("/lessons/{lesson_id}/complete", response_model=LessonOut)
def complete_lesson(lesson_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    """Lets a learner self-mark a lesson done when it has no quiz to grade completion."""
    lesson = db.get(Lesson, lesson_id)
    if lesson is None:
        raise AppError(404, "Lesson not found")
    if lesson.quiz is not None:
        raise AppError(409, "This lesson has a quiz — pass it to mark the lesson complete")

    mark_lesson_complete(db, user_id=user.id, lesson_id=lesson_id)
    return _to_lesson_out(lesson, completed=True)


@router.patch("/lessons/{lesson_id}", response_model=LessonOut)
def update_lesson(
    lesson_id: int, data: LessonUpdate, db: Session = Depends(get_db), _admin: User = Depends(require_admin)
):
    lesson = db.get(Lesson, lesson_id)
    if lesson is None:
        raise AppError(404, "Lesson not found")

    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(lesson, field, value)

    db.commit()
    db.refresh(lesson)
    return _to_lesson_out(lesson)


@router.delete("/lessons/{lesson_id}", status_code=204)
def delete_lesson(lesson_id: int, db: Session = Depends(get_db), _admin: User = Depends(require_admin)):
    lesson = db.get(Lesson, lesson_id)
    if lesson is None:
        raise AppError(404, "Lesson not found")
    db.delete(lesson)
    db.commit()
