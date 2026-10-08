"""Copies every row of real data from one database into another — e.g. from the
local MySQL catalog (30 courses, users, progress, ...) into a fresh production
PostgreSQL (Neon) — keeping ids, so every relationship stays intact.

The target must already have the schema (`alembic upgrade head`, which every
Render deploy runs) and no users yet; the script refuses otherwise, so it can't
clobber a live database. Sessions (refresh / password-reset tokens) aren't
copied: people just log in again. Avatars that point at local files are
cleared, since the files only exist on this machine (course covers are
shipped with the backend image, so they keep working).

Run from backend/, with the venv active:
    python copy_data.py --source "<source url>" --target "<target url>"
Either URL may instead come from the COPY_SOURCE_URL / COPY_TARGET_URL
environment variables, which keeps passwords out of shell history.
"""

import argparse
import os
import sys

from sqlalchemy import func, inspect, select, text

from app.db.session import make_engine
from app.models import Base

SKIPPED_TABLES = {"refresh_tokens", "password_reset_tokens", "alembic_version"}
BATCH_SIZE = 500


def _scrub(table_name: str, row: dict) -> dict:
    if table_name == "users" and (row.get("avatar_url") or "").startswith("/media/"):
        row["avatar_url"] = None
    return row


def copy_all(source_url: str, target_url: str) -> None:
    source = make_engine(source_url)
    target = make_engine(target_url)

    target_tables = set(inspect(target).get_table_names())
    missing = [t.name for t in Base.metadata.sorted_tables if t.name not in target_tables]
    if missing:
        sys.exit(f"Target has no schema yet (missing {missing}). Run `alembic upgrade head` against it first.")

    users = Base.metadata.tables["users"]
    with target.connect() as conn:
        if conn.execute(select(func.count()).select_from(users)).scalar():
            sys.exit("Target already has users - refusing to copy over a database that's in use.")

    tables = [t for t in Base.metadata.sorted_tables if t.name not in SKIPPED_TABLES]
    with source.connect() as src, target.begin() as dst:
        for table in tables:
            rows = [_scrub(table.name, dict(r._mapping)) for r in src.execute(select(table))]
            for start in range(0, len(rows), BATCH_SIZE):
                dst.execute(table.insert(), rows[start : start + BATCH_SIZE])
            print(f"{table.name:<24} {len(rows):>6} rows")

        if target.dialect.name == "postgresql":
            # Ids were copied explicitly, so move each id sequence past them or the next
            # insert would collide with an existing row.
            for table in tables:
                if "id" in table.c:
                    dst.execute(
                        text(
                            f"SELECT setval(pg_get_serial_sequence('{table.name}', 'id'), "
                            f"COALESCE((SELECT MAX(id) FROM {table.name}), 0) + 1, false)"
                        )
                    )
    print("Done.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--source", default=os.environ.get("COPY_SOURCE_URL"))
    parser.add_argument("--target", default=os.environ.get("COPY_TARGET_URL"))
    args = parser.parse_args()
    if not args.source or not args.target:
        parser.error("both --source and --target (or COPY_SOURCE_URL / COPY_TARGET_URL) are required")
    copy_all(args.source, args.target)


if __name__ == "__main__":
    main()
