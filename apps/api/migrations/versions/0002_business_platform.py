"""Business platform persistence.

Revision ID: 0002_business_platform
Revises: 0001_initial
"""
from alembic import op
import sqlalchemy as sa

revision = "0002_business_platform"
down_revision = "0001_initial"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table("leads",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(160), nullable=False),
        sa.Column("email", sa.String(320), nullable=False),
        sa.Column("source", sa.String(80), nullable=False, server_default="manual"),
        sa.Column("status", sa.String(40), nullable=False, server_default="new"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_leads_email", "leads", ["email"])
    op.create_table("opportunities",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("lead", sa.String(160), nullable=False),
        sa.Column("value", sa.Float(), nullable=False, server_default="0"),
        sa.Column("stage", sa.String(40), nullable=False, server_default="new"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
    )
    op.create_table("campaigns",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(160), nullable=False),
        sa.Column("channel", sa.String(80), nullable=False),
        sa.Column("status", sa.String(40), nullable=False, server_default="draft"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
    )
    op.create_table("marketplace_products",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(160), nullable=False),
        sa.Column("kind", sa.String(60), nullable=False),
        sa.Column("price", sa.Float(), nullable=False, server_default="0"),
        sa.Column("currency", sa.String(3), nullable=False, server_default="EUR"),
        sa.Column("status", sa.String(40), nullable=False, server_default="draft"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
    )
    op.create_table("deployments",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(160), nullable=False),
        sa.Column("image", sa.String(500), nullable=False),
        sa.Column("replicas", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("status", sa.String(40), nullable=False, server_default="approval-required"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("deployments")
    op.drop_table("marketplace_products")
    op.drop_table("campaigns")
    op.drop_table("opportunities")
    op.drop_index("ix_leads_email", table_name="leads")
    op.drop_table("leads")
