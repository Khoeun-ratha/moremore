from fastapi import APIRouter, Depends, Request, UploadFile
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user, get_db
from app.core.limiter import limiter
from app.models.user import User
from app.schemas.auth import (
    ChangePasswordRequest,
    ForgotPasswordRequest,
    ForgotPasswordResponse,
    LogoutRequest,
    RefreshRequest,
    ResetPasswordRequest,
    TokenPair,
    VerifyResetCodeRequest,
)
from app.schemas.user import MeUpdate, UserCreate, UserOut
from app.services.auth_service import (
    authenticate_user,
    change_password,
    issue_token_pair,
    refresh_access_token,
    register_user,
    request_password_reset,
    reset_password,
    revoke_refresh_token,
    update_avatar,
    update_profile,
    verify_reset_code,
)
from app.services.file_service import save_upload

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=UserOut, status_code=201)
@limiter.limit("10/minute")
def register(request: Request, data: UserCreate, db: Session = Depends(get_db)):
    user = register_user(db, data)
    return user


@router.post("/login", response_model=TokenPair)
@limiter.limit("10/minute")
def login(request: Request, form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = authenticate_user(db, form_data.username, form_data.password)
    return issue_token_pair(db, user)


@router.post("/refresh", response_model=TokenPair)
def refresh(data: RefreshRequest, db: Session = Depends(get_db)):
    return refresh_access_token(db, data.refresh_token)


@router.post("/logout", status_code=204)
def logout(data: LogoutRequest, db: Session = Depends(get_db)):
    revoke_refresh_token(db, data.refresh_token)


@router.get("/me", response_model=UserOut)
def me(current_user: User = Depends(get_current_user)):
    return current_user


@router.patch("/me", response_model=UserOut)
def update_me(data: MeUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return update_profile(db, current_user, data)


@router.post("/me/avatar", response_model=UserOut)
def update_my_avatar(
    file: UploadFile, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)
):
    _path, url, _size = save_upload("image", file)
    return update_avatar(db, current_user, url)


@router.post("/change-password", status_code=204)
def change_my_password(
    data: ChangePasswordRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)
):
    change_password(db, current_user, data.current_password, data.new_password)


@router.post("/forgot-password", response_model=ForgotPasswordResponse)
@limiter.limit("5/minute")
def forgot_password(request: Request, data: ForgotPasswordRequest, db: Session = Depends(get_db)):
    dev_code = request_password_reset(db, data.phone)
    return ForgotPasswordResponse(dev_code=dev_code)


@router.post("/verify-reset-code", status_code=204)
@limiter.limit("10/minute")
def verify_reset_code_route(request: Request, data: VerifyResetCodeRequest, db: Session = Depends(get_db)):
    verify_reset_code(db, data.phone, data.code)


@router.post("/reset-password", status_code=204)
@limiter.limit("10/minute")
def reset_password_route(request: Request, data: ResetPasswordRequest, db: Session = Depends(get_db)):
    reset_password(db, data.phone, data.code, data.new_password)
