"""Add deployment records used by the private Cloud module."""
from alembic import op
import sqlalchemy as sa

revision = "0003_deployments"
down_revision = "0002_business_sales_marketplace"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "deployments",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(160), nullable=False),
        sa.Column("image", sa.String(255), nullable=False),
        sa.Column("replicas", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("status", sa.String(40), nullable=False, server_default="approval-required"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("deployments")
