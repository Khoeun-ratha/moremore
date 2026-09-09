"""add super_admin role

Revision ID: d4f5a6b7c8d9
Revises: c3e4f5a6b7c8
Create Date: 2026-09-01 15:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd4f5a6b7c8d9'
down_revision: Union[str, None] = 'c3e4f5a6b7c8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Postgres enums are a separate named type with a fixed label set — adding
    # a value needs ALTER TYPE, not a column type change (which is a no-op
    # since the type name is unchanged). MySQL has no such separate type, so
    # its original alter_column approach still applies there.
    if op.get_bind().dialect.name == 'postgresql':
        op.execute("ALTER TYPE userrole ADD VALUE IF NOT EXISTS 'super_admin'")
    else:
        op.alter_column(
            'users',
            'role',
            existing_type=sa.Enum('user', 'admin', name='userrole'),
            type_=sa.Enum('user', 'admin', 'super_admin', name='userrole'),
            existing_nullable=False,
        )


def downgrade() -> None:
    op.execute("UPDATE users SET role = 'admin' WHERE role = 'super_admin'")
    if op.get_bind().dialect.name == 'postgresql':
        # Postgres can't drop an enum value directly — recreate the type.
        op.execute("ALTER TYPE userrole RENAME TO userrole_old")
        op.execute("CREATE TYPE userrole AS ENUM ('user', 'admin')")
        op.execute("ALTER TABLE users ALTER COLUMN role TYPE userrole USING role::text::userrole")
        op.execute("DROP TYPE userrole_old")
    else:
        op.alter_column(
            'users',
            'role',
            existing_type=sa.Enum('user', 'admin', 'super_admin', name='userrole'),
            type_=sa.Enum('user', 'admin', name='userrole'),
            existing_nullable=False,
        )
