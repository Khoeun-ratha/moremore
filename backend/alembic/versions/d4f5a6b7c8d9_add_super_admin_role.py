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
    op.alter_column(
        'users',
        'role',
        existing_type=sa.Enum('user', 'admin', name='userrole'),
        type_=sa.Enum('user', 'admin', 'super_admin', name='userrole'),
        existing_nullable=False,
    )


def downgrade() -> None:
    op.execute("UPDATE users SET role = 'admin' WHERE role = 'super_admin'")
    op.alter_column(
        'users',
        'role',
        existing_type=sa.Enum('user', 'admin', 'super_admin', name='userrole'),
        type_=sa.Enum('user', 'admin', name='userrole'),
        existing_nullable=False,
    )
