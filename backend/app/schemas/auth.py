from pydantic import BaseModel


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str


class LogoutRequest(BaseModel):
    refresh_token: str


class ForgotPasswordRequest(BaseModel):
    phone: str


class ForgotPasswordResponse(BaseModel):
    # Only populated when no real SMS provider is configured, so local/dev
    # testing can read the code straight from the response instead of the
    # server log. Always null once SMS_WEBHOOK_URL is set.
    dev_code: str | None = None


class VerifyResetCodeRequest(BaseModel):
    phone: str
    code: str


class ResetPasswordRequest(BaseModel):
    phone: str
    code: str
    new_password: str


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str
