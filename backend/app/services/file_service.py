import uuid
from io import BytesIO
from pathlib import Path

import cloudinary
import cloudinary.uploader
from fastapi import UploadFile

from app.core.config import settings
from app.core.exceptions import AppError

ALLOWED_EXTENSIONS: dict[str, set[str]] = {
    "video": {".mp4", ".mov", ".m4v", ".webm"},
    "pdf": {".pdf"},
    "image": {".jpg", ".jpeg", ".png", ".webp"},
}

SUBDIR_BY_KIND: dict[str, str] = {
    "video": "videos",
    "pdf": "pdfs",
    "image": "images",
}

# Cloudinary calls anything that isn't image/video a "raw" resource.
RESOURCE_TYPE_BY_KIND: dict[str, str] = {
    "video": "video",
    "pdf": "raw",
    "image": "image",
}

_configured = False


def _ensure_configured() -> None:
    global _configured
    if _configured:
        return
    cloudinary.config(
        cloud_name=settings.CLOUDINARY_CLOUD_NAME,
        api_key=settings.CLOUDINARY_API_KEY,
        api_secret=settings.CLOUDINARY_API_SECRET,
        secure=True,
    )
    _configured = True


def save_upload(kind: str, upload_file: UploadFile) -> tuple[str, int]:
    """Uploads to Cloudinary (free persistent storage) instead of local disk —
    Render's free web service has no persistent disk, so anything written
    locally is wiped on the next deploy."""
    if kind not in ALLOWED_EXTENSIONS:
        raise AppError(400, f"Unsupported kind '{kind}'. Must be one of {list(ALLOWED_EXTENSIONS)}")

    original_name = upload_file.filename or ""
    extension = Path(original_name).suffix.lower()
    if extension not in ALLOWED_EXTENSIONS[kind]:
        raise AppError(400, f"File extension '{extension}' not allowed for kind '{kind}'")

    max_bytes = settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024
    buffer = BytesIO()
    size = 0
    chunk_size = 1024 * 1024
    while chunk := upload_file.file.read(chunk_size):
        size += len(chunk)
        if size > max_bytes:
            raise AppError(413, f"File exceeds max upload size of {settings.MAX_UPLOAD_SIZE_MB}MB")
        buffer.write(chunk)

    if size == 0:
        raise AppError(400, "Uploaded file is empty")

    buffer.seek(0)
    _ensure_configured()
    result = cloudinary.uploader.upload_large(
        buffer,
        resource_type=RESOURCE_TYPE_BY_KIND[kind],
        folder=f"moremore/{SUBDIR_BY_KIND[kind]}",
        public_id=uuid.uuid4().hex,
    )
    return result["secure_url"], size
