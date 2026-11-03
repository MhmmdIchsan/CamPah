"""Add optional completion evidence photo."""
from alembic import op
import sqlalchemy as sa

revision = "004_evidence"
down_revision = "003_notifications"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("reports", sa.Column("completion_image_url", sa.Text(), nullable=True))


def downgrade():
    op.drop_column("reports", "completion_image_url")
