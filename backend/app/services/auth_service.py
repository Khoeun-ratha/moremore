import hashlib
import secrets
from datetime import datetime, timedelta, timezone


def _utcnow_naive() -> datetime:
    """Naive UTC datetime, matching the naive DateTime columns used for storage."""
    return datetime.now(timezone.utc).replace(tzinfo=None)

from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.exceptions import AppError
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.models.user import PasswordResetToken, RefreshToken, User
from app.schemas.auth import TokenPair
from app.schemas.user import MeUpdate, UserCreate
from app.services.sms_service import send_password_reset_sms


def _hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def register_user(db: Session, data: UserCreate) -> User:
    existing = db.query(User).filter(or_(User.email == data.email, User.phone == data.phone)).first()
    if existing:
        if existing.email == data.email:
            raise AppError(409, "Email already registered")
        raise AppError(409, "Phone number already registered")

    user = User(
        email=data.email,
        phone=data.phone,
        hashed_password=hash_password(data.password),
        full_name=data.full_name,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def authenticate_user(db: Session, identifier: str, password: str) -> User:
    """`identifier` may be either the user's email or phone number."""
    user = db.query(User).filter(or_(User.email == identifier, User.phone == identifier)).first()
    if not user or not verify_password(password, user.hashed_password):
        raise AppError(401, "Incorrect email/phone or password")
    if not user.is_active:
        raise AppError(403, "Account is disabled")
    return user


def issue_token_pair(db: Session, user: User) -> TokenPair:
    access_token = create_access_token(user.id, user.role.value)
    refresh_token = create_refresh_token(user.id)

    db.add(
        RefreshToken(
            user_id=user.id,
            token_hash=_hash_token(refresh_token),
            expires_at=_utcnow_naive() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
        )
    )
    db.commit()

    return TokenPair(access_token=access_token, refresh_token=refresh_token)


def refresh_access_token(db: Session, refresh_token: str) -> TokenPair:
    try:
        payload = decode_token(refresh_token)
    except ValueError as exc:
        raise AppError(401, "Invalid refresh token") from exc

    if payload.get("type") != "refresh":
        raise AppError(401, "Invalid token type")

    token_hash = _hash_token(refresh_token)
    stored = db.query(RefreshToken).filter(RefreshToken.token_hash == token_hash).first()
    if stored is None or stored.revoked or stored.expires_at < _utcnow_naive():
        raise AppError(401, "Refresh token is invalid or expired")

    user = db.get(User, stored.user_id)
    if user is None or not user.is_active:
        raise AppError(401, "User not found or inactive")

    # rotate: revoke the used refresh token and issue a new pair
    stored.revoked = True
    db.commit()

    return issue_token_pair(db, user)


def revoke_refresh_token(db: Session, refresh_token: str) -> None:
    token_hash = _hash_token(refresh_token)
    stored = db.query(RefreshToken).filter(RefreshToken.token_hash == token_hash).first()
    if stored is not None:
        stored.revoked = True
        db.commit()


def _generate_otp() -> str:
    return f"{secrets.randbelow(1_000_000):06d}"


def request_password_reset(db: Session, phone: str) -> str | None:
    """Always succeeds silently — doesn't reveal whether the phone is registered.

    Returns the OTP only when no real SMS provider is configured, so the API
    caller can surface it directly (e.g. in the app UI) for local/dev testing
    instead of requiring access to the server log.
    """
    user = db.query(User).filter(User.phone == phone).first()
    if user is None:
        return None

    code = _generate_otp()
    db.add(
        PasswordResetToken(
            user_id=user.id,
            token_hash=_hash_token(code),
            expires_at=_utcnow_naive() + timedelta(minutes=settings.PASSWORD_RESET_TOKEN_EXPIRE_MINUTES),
        )
    )
    db.commit()
    send_password_reset_sms(user.phone, code)
    return None if settings.SMS_WEBHOOK_URL else code


def _find_valid_reset_token(db: Session, phone: str, code: str) -> tuple[User, PasswordResetToken] | None:
    """Looks up an unused, unexpired reset code for the given phone.

    Scoping the lookup to the user found via `phone` (rather than a global
    hash lookup) keeps two users from ever colliding on the same short OTP.
    """
    user = db.query(User).filter(User.phone == phone).first()
    if user is None:
        return None

    token_hash = _hash_token(code)
    stored = (
        db.query(PasswordResetToken)
        .filter(PasswordResetToken.user_id == user.id, PasswordResetToken.token_hash == token_hash)
        .first()
    )
    if stored is None or stored.used or stored.expires_at < _utcnow_naive():
        return None
    return user, stored


def verify_reset_code(db: Session, phone: str, code: str) -> None:
    if _find_valid_reset_token(db, phone, code) is None:
        raise AppError(400, "This reset code is invalid or has expired")


def reset_password(db: Session, phone: str, code: str, new_password: str) -> None:
    result = _find_valid_reset_token(db, phone, code)
    if result is None:
        raise AppError(400, "This reset code is invalid or has expired")
    user, stored = result

    user.hashed_password = hash_password(new_password)
    stored.used = True
    # A password reset means any existing session may be compromised or forgotten;
    # force re-login everywhere rather than leaving old refresh tokens usable.
    db.query(RefreshToken).filter(
        RefreshToken.user_id == user.id, RefreshToken.revoked.is_(False)
    ).update({"revoked": True})
    db.commit()


def change_password(db: Session, user: User, current_password: str, new_password: str) -> None:
    if not verify_password(current_password, user.hashed_password):
        raise AppError(401, "Current password is incorrect")
    user.hashed_password = hash_password(new_password)
    db.commit()


def admin_set_password(db: Session, user: User, new_password: str) -> None:
    """Admin-initiated password reset — no current-password check, since the
    admin isn't the account owner. Revokes existing sessions like every other
    password change, since the old password may have been compromised.
    """
    user.hashed_password = hash_password(new_password)
    db.query(RefreshToken).filter(
        RefreshToken.user_id == user.id, RefreshToken.revoked.is_(False)
    ).update({"revoked": True})
    db.commit()


def update_profile(db: Session, user: User, data: MeUpdate) -> User:
    updates = data.model_dump(exclude_unset=True)

    new_email = updates.get("email")
    if new_email is not None and new_email != user.email:
        if db.query(User).filter(User.email == new_email).first():
            raise AppError(409, "Email already registered")

    new_phone = updates.get("phone")
    if new_phone is not None and new_phone != user.phone:
        if db.query(User).filter(User.phone == new_phone).first():
            raise AppError(409, "Phone number already registered")

    for field, value in updates.items():
        setattr(user, field, value)

    db.commit()
    db.refresh(user)
    return user


def update_avatar(db: Session, user: User, avatar_url: str) -> User:
    user.avatar_url = avatar_url
    db.commit()
    db.refresh(user)
    return user
