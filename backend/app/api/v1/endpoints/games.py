from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user, get_db
from app.models.game import GameAttempt
from app.models.user import User
from app.schemas.game import GameAttemptOut, GameQuestionOut, GameResult, GameSubmission
from app.services.game_service import get_random_questions, submit_game

router = APIRouter(prefix="/games", tags=["games"])


@router.get("/random-quiz", response_model=list[GameQuestionOut])
def get_random_quiz(
    course_id: int | None = Query(default=None),
    count: int = Query(default=10, ge=1, le=30),
    db: Session = Depends(get_db),
    _user: User = Depends(get_current_user),
):
    """A random sample of questions drawn from every quiz on the platform,
    or scoped to one course. Stateless: nothing is recorded until submit."""
    return get_random_questions(db, course_id=course_id, count=count)


@router.post("/random-quiz/submit", response_model=GameResult)
def submit_random_quiz(
    submission: GameSubmission,
    course_id: int | None = Query(default=None),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return submit_game(db, user_id=user.id, course_id=course_id, submission=submission)


@router.get("/my-attempts", response_model=list[GameAttemptOut])
def my_game_attempts(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return (
        db.query(GameAttempt)
        .filter(GameAttempt.user_id == user.id)
        .order_by(GameAttempt.submitted_at.desc())
        .limit(20)
        .all()
    )
