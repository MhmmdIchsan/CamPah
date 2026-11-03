"""Add in-app notifications."""
from alembic import op
import sqlalchemy as sa

revision = "003_notifications"
down_revision = "002_followup"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table("notifications",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("report_id", sa.Integer(), sa.ForeignKey("reports.id"), nullable=False),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("is_read", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False))
    op.create_index("ix_notifications_user_id", "notifications", ["user_id"])


def downgrade():
    op.drop_index("ix_notifications_user_id", table_name="notifications")
    op.drop_table("notifications")
