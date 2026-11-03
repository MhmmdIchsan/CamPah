"""Record the team or officer responsible for a report."""
from alembic import op
import sqlalchemy as sa

revision = "006_assignment"
down_revision = "005_category_review"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("reports", sa.Column("assigned_name", sa.String(120), nullable=True))


def downgrade():
    op.drop_column("reports", "assigned_name")
