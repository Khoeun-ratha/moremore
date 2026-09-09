from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.models.user import Gender, UserRole


class UserCreate(BaseModel):
    email: EmailStr
    phone: str
    password: str = Field(min_length=8)
    full_name: str

    @field_validator("full_name")
    @classmethod
    def full_name_not_blank(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Full name is required")
        return v.strip()

    @field_validator("phone")
    @classmethod
    def phone_not_blank(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Phone number is required")
        return v.strip()


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
