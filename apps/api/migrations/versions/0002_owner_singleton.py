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
    # SQLite does not support ALTER TABLE ... ADD CONSTRAINT.  Use Alembic's
    # batch mode so the migration is portable to the SQLite database used by CI.
    with op.batch_alter_table("owner_identity") as batch_op:
        batch_op.add_column(
            sa.Column("singleton_key", sa.SmallInteger(), nullable=False, server_default="1")
        )
        batch_op.create_unique_constraint(
            "uq_owner_identity_singleton", ["singleton_key"]
        )


def downgrade() -> None:
    with op.batch_alter_table("owner_identity") as batch_op:
        batch_op.drop_constraint("uq_owner_identity_singleton", type_="unique")
        batch_op.drop_column("singleton_key")
