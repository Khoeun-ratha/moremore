"""add gender and avatar to users

Revision ID: b2d3e4f5a6b7
Revises: a1c2d3e4f5a6
Create Date: 2026-07-15 11:05:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b2d3e4f5a6b7'
down_revision: Union[str, None] = 'a1c2d3e4f5a6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # On Postgres, ADD COLUMN doesn't auto-create a referenced enum type the
    # way CREATE TABLE does — it must be created explicitly first. A no-op on
    # MySQL, which has no separate enum-type object.
    gender_enum = sa.Enum('male', 'female', 'other', 'prefer_not_to_say', name='gender')
    gender_enum.create(op.get_bind(), checkfirst=True)
    op.add_column('users', sa.Column('gender', gender_enum, nullable=True))
    op.add_column('users', sa.Column('avatar_url', sa.String(length=500), nullable=True))


def downgrade() -> None:
    op.drop_column('users', 'avatar_url')
    op.drop_column('users', 'gender')
    sa.Enum(name='gender').drop(op.get_bind(), checkfirst=True)
