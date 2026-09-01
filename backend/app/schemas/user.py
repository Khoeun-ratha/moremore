from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.models.user import Gender, UserRole


class UserCreate(BaseModel):
    email: EmailStr
    phone: str
    password: str
    full_name: str


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: EmailStr
    phone: str | None
    full_name: str
    gender: Gender | None
    avatar_url: str | None
    role: UserRole
    is_active: bool
    created_at: datetime


class UserUpdate(BaseModel):
    full_name: str | None = None
    email: EmailStr | None = None
    is_active: bool | None = None
    role: UserRole | None = None


class UserPasswordReset(BaseModel):
    new_password: str = Field(min_length=8)


class MeUpdate(BaseModel):
    full_name: str | None = None
    phone: str | None = None
    gender: Gender | None = None
    email: EmailStr | None = None
