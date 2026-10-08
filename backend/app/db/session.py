from collections.abc import Generator

from sqlalchemy import create_engine, event
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import settings


def make_engine(database_url: str, ssl_ca_path: str = ""):
    connect_args = {}
    if database_url.startswith("sqlite"):
        connect_args = {"check_same_thread": False}
    elif ssl_ca_path and database_url.startswith("mysql"):
        connect_args = {"ssl": {"ca": ssl_ca_path}}
    elif ssl_ca_path and database_url.startswith("postgresql"):
        connect_args = {"sslmode": "verify-ca", "sslrootcert": ssl_ca_path}
    eng = create_engine(database_url, connect_args=connect_args, pool_pre_ping=True)
    if database_url.startswith("sqlite"):
        # SQLite ignores foreign keys unless asked per-connection; without this, tests pass on
        # deletes that PostgreSQL/MySQL reject with an FK violation in production.
        @event.listens_for(eng, "connect")
        def _enable_sqlite_foreign_keys(dbapi_connection, _record):
            cursor = dbapi_connection.cursor()
            cursor.execute("PRAGMA foreign_keys=ON")
            cursor.close()

    return eng


engine = make_engine(settings.DATABASE_URL, settings.DATABASE_SSL_CA_PATH)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
