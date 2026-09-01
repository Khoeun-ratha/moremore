from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.models.certificate import Certificate, generate_certificate_number
from app.models.course import Course, Lesson
from app.models.progress import LessonProgress
from app.schemas.progress import CourseProgressOut, OverallProgressOut


def mark_lesson_complete(db: Session, user_id: int, lesson_id: int) -> None:
    progress = (
        db.query(LessonProgress)
        .filter(LessonProgress.user_id == user_id, LessonProgress.lesson_id == lesson_id)
        .first()
    )
    if progress is None:
        progress = LessonProgress(user_id=user_id, lesson_id=lesson_id)
        db.add(progress)

    progress.completed = True
    progress.completed_at = datetime.now(timezone.utc).replace(tzinfo=None)
    db.commit()

    lesson = db.get(Lesson, lesson_id)
    if lesson is not None:
        _maybe_issue_certificate(db, user_id=user_id, course_id=lesson.course_id)


def _maybe_issue_certificate(db: Session, user_id: int, course_id: int) -> None:
    course = db.get(Course, course_id)
    if course is None or not course.lessons:
        return

    lesson_ids = [lesson.id for lesson in course.lessons]
    completed_count = (
        db.query(LessonProgress)
        .filter(
            LessonProgress.user_id == user_id,
            LessonProgress.lesson_id.in_(lesson_ids),
            LessonProgress.completed.is_(True),
        )
        .count()
    )
    if completed_count < len(lesson_ids):
        return

    existing = (
        db.query(Certificate)
        .filter(Certificate.user_id == user_id, Certificate.course_id == course_id)
        .first()
    )
    if existing is not None:
        return

    db.add(
        Certificate(
            user_id=user_id,
            course_id=course_id,
            certificate_number=generate_certificate_number(),
        )
    )
    db.commit()


def get_overall_progress(db: Session, user_id: int) -> OverallProgressOut:
    courses = db.query(Course).all()
    completed_lesson_ids = {
        lp.lesson_id
        for lp in db.query(LessonProgress).filter(LessonProgress.user_id == user_id, LessonProgress.completed.is_(True))
    }
    certificate_numbers = {
        cert.course_id: cert.certificate_number
        for cert in db.query(Certificate).filter(Certificate.user_id == user_id)
    }

    course_progress: list[CourseProgressOut] = []
    total_lessons_all = 0
    total_completed_all = 0

    for course in courses:
        lesson_ids = [lesson.id for lesson in course.lessons]
        total = len(lesson_ids)
        completed = sum(1 for lid in lesson_ids if lid in completed_lesson_ids)
        total_lessons_all += total
        total_completed_all += completed

        course_progress.append(
            CourseProgressOut(
                course_id=course.id,
                course_title=course.title,
                total_lessons=total,
                completed_lessons=completed,
                percentage=round((completed / total) * 100, 2) if total else 0.0,
                certificate_number=certificate_numbers.get(course.id),
            )
        )

    overall_percentage = round((total_completed_all / total_lessons_all) * 100, 2) if total_lessons_all else 0.0

    return OverallProgressOut(courses=course_progress, overall_percentage=overall_percentage)


def get_course_progress(db: Session, user_id: int, course_id: int) -> CourseProgressOut:
    course = db.get(Course, course_id)
    if course is None:
        from app.core.exceptions import AppError

        raise AppError(404, "Course not found")

    lesson_ids = [lesson.id for lesson in course.lessons]
    total = len(lesson_ids)
    completed = 0
    if lesson_ids:
        completed = (
            db.query(LessonProgress)
            .filter(
                LessonProgress.user_id == user_id,
                LessonProgress.lesson_id.in_(lesson_ids),
                LessonProgress.completed.is_(True),
            )
            .count()
        )

    certificate = (
        db.query(Certificate)
        .filter(Certificate.user_id == user_id, Certificate.course_id == course_id)
        .first()
    )

    return CourseProgressOut(
        course_id=course.id,
        course_title=course.title,
        total_lessons=total,
        completed_lessons=completed,
        percentage=round((completed / total) * 100, 2) if total else 0.0,
        certificate_number=certificate.certificate_number if certificate else None,
    )
