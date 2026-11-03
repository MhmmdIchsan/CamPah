"""Add human review of AI categories."""
from alembic import op
import sqlalchemy as sa

revision = "005_category_review"
down_revision = "004_evidence"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("reports", sa.Column("corrected_category", sa.String(32), nullable=True))
    op.add_column("reports", sa.Column("category_note", sa.Text(), nullable=True))
    op.add_column("reports", sa.Column("category_reviewer_id", sa.Integer(), nullable=True))
    op.add_column("reports", sa.Column("category_reviewed_at", sa.DateTime(timezone=True), nullable=True))


def downgrade():
    op.drop_column("reports", "category_note")
    op.drop_column("reports", "corrected_category")
    op.drop_column("reports", "category_reviewed_at")
    op.drop_column("reports", "category_reviewer_id")
