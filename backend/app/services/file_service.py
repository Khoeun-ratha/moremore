import uuid
from pathlib import Path

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


def _media_root() -> Path:
    return Path(settings.MEDIA_ROOT)


def save_upload(kind: str, upload_file: UploadFile) -> tuple[Path, str, int]:
    if kind not in ALLOWED_EXTENSIONS:
        raise AppError(400, f"Unsupported kind '{kind}'. Must be one of {list(ALLOWED_EXTENSIONS)}")

    original_name = upload_file.filename or ""
    extension = Path(original_name).suffix.lower()
    if extension not in ALLOWED_EXTENSIONS[kind]:
        raise AppError(400, f"File extension '{extension}' not allowed for kind '{kind}'")

    max_bytes = settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024
    subdir = _media_root() / SUBDIR_BY_KIND[kind]
    subdir.mkdir(parents=True, exist_ok=True)

    stored_name = f"{uuid.uuid4().hex}{extension}"
    destination = subdir / stored_name

    size = 0
    chunk_size = 1024 * 1024
    with destination.open("wb") as out_file:
        while chunk := upload_file.file.read(chunk_size):
            size += len(chunk)
            if size > max_bytes:
                out_file.close()
                destination.unlink(missing_ok=True)
                raise AppError(413, f"File exceeds max upload size of {settings.MAX_UPLOAD_SIZE_MB}MB")
            out_file.write(chunk)

    if size == 0:
        destination.unlink(missing_ok=True)
        raise AppError(400, "Uploaded file is empty")

    url = f"/media/{SUBDIR_BY_KIND[kind]}/{stored_name}"
    return destination, url, size
