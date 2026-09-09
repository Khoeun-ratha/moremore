import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from app.api.v1.router import api_router
from app.core.config import settings
from app.core.exceptions import AppError, app_error_handler, unhandled_exception_handler
from app.core.limiter import limiter
from app.core.privacy_policy import PRIVACY_POLICY_HTML
from app.core.terms_of_service import TERMS_OF_SERVICE_HTML

# Without this, the root logger's default level (WARNING) silently swallows every
# logger.info() call in the app — including the dev fallback that logs OTP/reset
# codes when no SMS/SMTP provider is configured, so they'd never appear anywhere.
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")

app = FastAPI(title="Learning Platform API", version="1.0.0")

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_exception_handler(AppError, app_error_handler)
app.add_exception_handler(Exception, unhandled_exception_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list or ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/media", StaticFiles(directory=settings.MEDIA_ROOT), name="media")
app.include_router(api_router, prefix="/api/v1")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/privacy-policy", response_class=HTMLResponse)
def privacy_policy():
    return PRIVACY_POLICY_HTML


@app.get("/terms-of-service", response_class=HTMLResponse)
def terms_of_service():
    return TERMS_OF_SERVICE_HTML
