from fastapi import APIRouter, Depends, Query
from sqlalchemy import or_
from sqlalchemy.orm import Session, selectinload

from app.core.dependencies import get_current_user, get_db, require_admin
from app.core.exceptions import AppError
from app.models.certificate import Certificate
from app.models.course import Course
from app.models.user import User
from app.schemas.certificate import CertificateAdminOut, CertificateOut
from app.schemas.common import Page

router = APIRouter(prefix="/certificates", tags=["certificates"])


def _to_admin_out(c: Certificate) -> CertificateAdminOut:
    return CertificateAdminOut(
        id=c.id,
        course_id=c.course_id,
        course_title=c.course.title,
        user_id=c.user_id,
        user_full_name=c.user.full_name,
        user_email=c.user.email,
        certificate_number=c.certificate_number,
        issued_at=c.issued_at,
    )


@router.get("", response_model=Page)
def list_certificates(
    q: str | None = Query(None, description="Search by certificate number, learner name/email, or course title"),
    user_id: int | None = None,
    course_id: int | None = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    query = (
        db.query(Certificate)
        .join(User, Certificate.user_id == User.id)
        .join(Course, Certificate.course_id == Course.id)
        .options(selectinload(Certificate.course), selectinload(Certificate.user))
    )
    if user_id:
        query = query.filter(Certificate.user_id == user_id)
    if course_id:
        query = query.filter(Certificate.course_id == course_id)
    if q:
        like = f"%{q}%"
        query = query.filter(
            or_(
                Certificate.certificate_number.ilike(like),
                User.full_name.ilike(like),
                User.email.ilike(like),
                Course.title.ilike(like),
            )
        )

    total = query.count()
    certs = query.order_by(Certificate.issued_at.desc()).offset((page - 1) * page_size).limit(page_size).all()

    return Page(items=[_to_admin_out(c) for c in certs], total=total, page=page, page_size=page_size)


@router.get("/me", response_model=list[CertificateOut])
def my_certificates(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    certs = (
        db.query(Certificate)
        .options(selectinload(Certificate.course))
        .filter(Certificate.user_id == user.id)
        .order_by(Certificate.issued_at.desc())
        .all()
    )
    return [
        CertificateOut(
            id=c.id,
            course_id=c.course_id,
            course_title=c.course.title,
            certificate_number=c.certificate_number,
            issued_at=c.issued_at,
        )
        for c in certs
    ]


@router.get("/{certificate_id}", response_model=CertificateAdminOut)
def get_certificate(certificate_id: int, db: Session = Depends(get_db), _admin: User = Depends(require_admin)):
    cert = (
        db.query(Certificate)
        .options(selectinload(Certificate.course), selectinload(Certificate.user))
        .filter(Certificate.id == certificate_id)
        .first()
    )
    if cert is None:
        raise AppError(404, "Certificate not found")
    return _to_admin_out(cert)
