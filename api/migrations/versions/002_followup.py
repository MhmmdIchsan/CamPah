"""Add public follow-up notes to status history."""
from alembic import op
import sqlalchemy as sa

revision = "002_followup"
down_revision = "001_initial"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("report_status_history", sa.Column("note", sa.Text(), nullable=True))
    op.add_column("report_status_history", sa.Column("is_correction", sa.Boolean(), nullable=False, server_default=sa.false()))


def downgrade():
    op.drop_column("report_status_history", "is_correction")
    op.drop_column("report_status_history", "note")
