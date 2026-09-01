from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import settings
from app.core.limiter import limiter
from app.db.session import get_db, make_engine
from app.models import Base

TEST_DB_PATH = Path(__file__).resolve().parent.parent / "test.db"


@pytest.fixture(scope="session")
def engine():
    if TEST_DB_PATH.exists():
        TEST_DB_PATH.unlink()

    test_url = settings.TEST_DATABASE_URL or f"sqlite:///{TEST_DB_PATH}"
    eng = make_engine(test_url)
    Base.metadata.create_all(bind=eng)
    yield eng
    Base.metadata.drop_all(bind=eng)
    eng.dispose()
    if TEST_DB_PATH.exists():
        TEST_DB_PATH.unlink()


@pytest.fixture(autouse=True)
def _clean_tables(engine):
    yield
    with engine.begin() as conn:
        for table in reversed(Base.metadata.sorted_tables):
            conn.execute(table.delete())


@pytest.fixture(autouse=True)
def _reset_rate_limiter():
    limiter.reset()
    yield


@pytest.fixture(scope="session", autouse=True)
def _isolate_media_root(tmp_path_factory):
    # app.main mounts StaticFiles(directory=settings.MEDIA_ROOT) once at import time, so the
    # media root must be fixed for the whole test session rather than per-test.
    media_root = tmp_path_factory.mktemp("media_root")
    for sub in ("videos", "pdfs", "images"):
        (media_root / sub).mkdir()
    settings.MEDIA_ROOT = str(media_root)
    yield media_root


@pytest.fixture
def db_session(engine) -> Session:
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture
def client(engine):
    from app.main import app

    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

    def override_get_db():
        db = TestingSessionLocal()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


def _phone_for(email: str) -> str:
    """Deterministic, unique-enough fake phone number for a given test email."""
    return f"+1{abs(hash(email)) % 10_000_000_000:010d}"


def _register_and_login(client: TestClient, email: str, password: str = "Password123!") -> dict:
    client.post(
        "/api/v1/auth/register",
        json={"email": email, "phone": _phone_for(email), "password": password, "full_name": "Test User"},
    )
    resp = client.post(
        "/api/v1/auth/login",
        data={"username": email, "password": password},
    )
    tokens = resp.json()
    return {"Authorization": f"Bearer {tokens['access_token']}"}


@pytest.fixture
def user_headers(client):
    return _register_and_login(client, "user@example.com")


def _become(client, engine, email: str, role: "UserRole"):
    from app.models.user import User

    with engine.begin() as conn:
        conn.execute(User.__table__.update().where(User.__table__.c.email == email).values(role=role))

    # the access token embeds the role at issue time, so log in again to get an
    # access token reflecting the new role.
    resp = client.post(
        "/api/v1/auth/login",
        data={"username": email, "password": "Password123!"},
    )
    tokens = resp.json()
    return {"Authorization": f"Bearer {tokens['access_token']}"}


@pytest.fixture
def admin_headers(client, db_session, engine):
    from app.models.user import UserRole

    _register_and_login(client, "admin@example.com")
    return _become(client, engine, "admin@example.com", UserRole.admin)


@pytest.fixture
def super_admin_headers(client, db_session, engine):
    from app.models.user import UserRole

    _register_and_login(client, "superadmin@example.com")
    return _become(client, engine, "superadmin@example.com", UserRole.super_admin)
