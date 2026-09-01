from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    DATABASE_URL: str
    TEST_DATABASE_URL: str = ""

    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 45
    REFRESH_TOKEN_EXPIRE_DAYS: int = 14

    CORS_ORIGINS: str = ""

    MEDIA_ROOT: str = "media"
    MAX_UPLOAD_SIZE_MB: int = 500

    FIRST_ADMIN_EMAIL: str = ""
    FIRST_ADMIN_PASSWORD: str = ""

    # Password reset OTP. When SMS_WEBHOOK_URL is blank, the code is logged
    # instead of texted — lets the flow work out of the box without an SMS provider.
    PASSWORD_RESET_TOKEN_EXPIRE_MINUTES: int = 10
    SMS_WEBHOOK_URL: str = ""
    SMS_WEBHOOK_TOKEN: str = ""

    @property
    def cors_origins_list(self) -> list[str]:
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip()]


settings = Settings()
