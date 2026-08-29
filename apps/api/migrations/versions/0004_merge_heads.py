"""Merge the business/deployments and owner singleton migration branches.

Revision ID: 0004_merge_heads
Revises: 0003_deployments, 0002_owner_singleton
"""

from alembic import op

revision = "0004_merge_heads"
down_revision = ("0003_deployments", "0002_owner_singleton")
branch_labels = None
depends_on = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
