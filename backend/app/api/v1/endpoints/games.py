from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user, get_db, require_admin
from app.models.game import GameAttempt
from app.models.user import User
from app.schemas.common import Page
from app.schemas.game import (
    GameAttemptAdminOut,
    GameAttemptOut,
    GameQuestionOut,
    GameResult,
    GameSubmission,
    LeaderboardEntryOut,
)
from app.services.game_service import (
    delete_game_attempt_admin,
    get_leaderboard,
    get_random_questions,
    list_game_attempts_admin,
    submit_game,
)

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


@router.get("/leaderboard", response_model=list[LeaderboardEntryOut])
def quick_challenge_leaderboard(
    limit: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
    _user: User = Depends(get_current_user),
):
    """Every player's single best Quick Challenge round, ranked by score."""
    return get_leaderboard(db, limit=limit)


@router.get("/admin/attempts", response_model=Page)
def list_all_game_attempts(
    q: str | None = Query(None, description="Search by submitting user's name or email"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """Every Quick Challenge attempt platform-wide, for admin monitoring
    and moderation (e.g. removing a suspicious run from the leaderboard)."""
    items, total = list_game_attempts_admin(db, page=page, page_size=page_size, q=q)
    return Page(items=items, total=total, page=page, page_size=page_size)


@router.delete("/admin/attempts/{attempt_id}", status_code=204)
def delete_game_attempt(
    attempt_id: int, db: Session = Depends(get_db), _admin: User = Depends(require_admin)
):
    delete_game_attempt_admin(db, attempt_id)
