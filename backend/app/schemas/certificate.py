from datetime import datetime

from pydantic import BaseModel


class CertificateOut(BaseModel):
    id: int
    course_id: int
    course_title: str
    certificate_number: str
    issued_at: datetime


class CertificateAdminOut(CertificateOut):
    user_id: int
    user_full_name: str
    user_email: str
