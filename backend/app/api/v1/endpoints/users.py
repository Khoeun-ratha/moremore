from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.dependencies import get_db, require_admin
from app.core.exceptions import AppError
from app.models.user import User, UserRole
from app.schemas.progress import OverallProgressOut
from app.schemas.user import UserOut, UserPasswordReset, UserUpdate
from app.services.auth_service import admin_set_password
from app.services.progress_service import get_overall_progress

router = APIRouter(prefix="/users", tags=["users"])

_ADMIN_TIER = (UserRole.admin, UserRole.super_admin)


def _require_super_admin_for_admin_target(admin: User, target: User) -> None:
    """Only a super admin may touch an existing admin/super-admin account.

    A regular admin keeps full access to plain user accounts, but can't edit,
    reset the password of, or delete another admin — that would let one
    admin account compromise or lock out another.
    """
    if target.role in _ADMIN_TIER and admin.role != UserRole.super_admin:
        raise AppError(403, "Only a super admin can manage admin accounts")


@router.get("", response_model=list[UserOut])
def list_users(db: Session = Depends(get_db), _admin: User = Depends(require_admin)):
    return db.query(User).order_by(User.id).all()


@router.get("/{user_id}", response_model=UserOut)
def get_user(user_id: int, db: Session = Depends(get_db), _admin: User = Depends(require_admin)):
    user = db.get(User, user_id)
    if user is None:
        raise AppError(404, "User not found")
    return user


@router.patch("/{user_id}", response_model=UserOut)
def update_user(user_id: int, data: UserUpdate, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    user = db.get(User, user_id)
    if user is None:
        raise AppError(404, "User not found")

    updates = data.model_dump(exclude_unset=True)

    role_change = "role" in updates and updates["role"] != user.role
    if role_change and admin.role != UserRole.super_admin:
        raise AppError(403, "Only a super admin can grant or revoke admin roles")
    _require_super_admin_for_admin_target(admin, user)

    new_email = updates.get("email")
    if new_email is not None and new_email != user.email:
        if db.query(User).filter(User.email == new_email, User.id != user_id).first():
            raise AppError(409, "Email already registered")

    for field, value in updates.items():
        setattr(user, field, value)

    db.commit()
    db.refresh(user)
    return user


@router.post("/{user_id}/reset-password", status_code=204)
def reset_user_password(
    user_id: int, data: UserPasswordReset, db: Session = Depends(get_db), admin: User = Depends(require_admin)
):
    user = db.get(User, user_id)
    if user is None:
        raise AppError(404, "User not found")
    _require_super_admin_for_admin_target(admin, user)
    admin_set_password(db, user, data.new_password)


@router.delete("/{user_id}", status_code=204)
def delete_user(user_id: int, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    user = db.get(User, user_id)
    if user is None:
        raise AppError(404, "User not found")
    _require_super_admin_for_admin_target(admin, user)
    db.delete(user)
    db.commit()


@router.get("/{user_id}/progress", response_model=OverallProgressOut)
def user_progress(user_id: int, db: Session = Depends(get_db), _admin: User = Depends(require_admin)):
    user = db.get(User, user_id)
    if user is None:
        raise AppError(404, "User not found")
    return get_overall_progress(db, user_id)
