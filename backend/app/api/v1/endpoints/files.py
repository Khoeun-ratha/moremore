from fastapi import APIRouter, Depends, UploadFile

from app.core.dependencies import require_admin
from app.models.user import User
from app.schemas.file_asset import FileUploadOut
from app.services.file_service import save_upload

router = APIRouter(prefix="/files", tags=["files"])


@router.post("/upload", response_model=FileUploadOut)
def upload_file(kind: str, file: UploadFile, _admin: User = Depends(require_admin)):
    _path, url, size = save_upload(kind, file)
    return FileUploadOut(url=url, filename=file.filename or "", kind=kind, size_bytes=size)
