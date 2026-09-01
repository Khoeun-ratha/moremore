import logging

import httpx

from app.core.config import settings

logger = logging.getLogger("app.sms")


def send_password_reset_sms(phone: str, code: str) -> None:
    """Sends the password-reset OTP to the user's phone.

    Falls back to logging the code when no SMS provider is configured, so the
    reset flow works out of the box in dev/self-hosted setups without one.
    """
    if not settings.SMS_WEBHOOK_URL:
        logger.info("Password reset requested for %s - code: %s", phone, code)
        return

    message = (
        f"Your password reset code is {code}. "
        f"It expires in {settings.PASSWORD_RESET_TOKEN_EXPIRE_MINUTES} minutes."
    )
    headers = {"Authorization": f"Bearer {settings.SMS_WEBHOOK_TOKEN}"} if settings.SMS_WEBHOOK_TOKEN else {}
    httpx.post(settings.SMS_WEBHOOK_URL, json={"to": phone, "message": message}, headers=headers, timeout=10)
