"""add game attempts

Revision ID: a7b8c9d0e1f2
Revises: d4f5a6b7c8d9
Create Date: 2026-09-02 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a7b8c9d0e1f2'
down_revision: Union[str, None] = 'd4f5a6b7c8d9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table('game_attempts',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('user_id', sa.Integer(), nullable=False),
    sa.Column('course_id', sa.Integer(), nullable=True),
    sa.Column('score', sa.Integer(), nullable=False),
    sa.Column('total', sa.Integer(), nullable=False),
    sa.Column('submitted_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
    sa.ForeignKeyConstraint(['course_id'], ['courses.id'], ),
    sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
    sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_game_attempts_course_id'), 'game_attempts', ['course_id'], unique=False)
    op.create_index(op.f('ix_game_attempts_user_id'), 'game_attempts', ['user_id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_game_attempts_user_id'), table_name='game_attempts')
    op.drop_index(op.f('ix_game_attempts_course_id'), table_name='game_attempts')
    op.drop_table('game_attempts')
