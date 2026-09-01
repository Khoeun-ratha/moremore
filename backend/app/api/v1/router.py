from fastapi import APIRouter

from app.api.v1.endpoints import (
    auth,
    certificates,
    courses,
    feedback,
    files,
    lessons,
    progress,
    quizzes,
    reviews,
    users,
)

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(courses.router)
api_router.include_router(lessons.router)
api_router.include_router(quizzes.router)
api_router.include_router(files.router)
api_router.include_router(progress.router)
api_router.include_router(certificates.router)
api_router.include_router(reviews.router)
api_router.include_router(feedback.router)
