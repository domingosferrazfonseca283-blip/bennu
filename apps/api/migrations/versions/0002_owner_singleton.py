"""Enforce one Owner identity.

Revision ID: 0002_owner_singleton
"""
from alembic import op
import sqlalchemy as sa

revision = "0002_owner_singleton"
down_revision = "0001_initial"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("owner_identity", sa.Column("singleton_key", sa.SmallInteger(), nullable=False, server_default="1"))
    op.create_unique_constraint("uq_owner_identity_singleton", "owner_identity", ["singleton_key"])


def downgrade() -> None:
    op.drop_constraint("uq_owner_identity_singleton", "owner_identity", type_="unique")
    op.drop_column("owner_identity", "singleton_key")
