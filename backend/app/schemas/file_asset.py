from pydantic import BaseModel


class FileUploadOut(BaseModel):
    url: str
    filename: str
    kind: str
    size_bytes: int
