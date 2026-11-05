"""Link report assignments to officer accounts without changing legacy names."""
from alembic import op
import sqlalchemy as sa

revision = "007_officer_assignment"
down_revision = "006_assignment"
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table("reports") as batch:
        batch.add_column(sa.Column("assigned_user_id", sa.Integer(), nullable=True))
        batch.create_foreign_key("fk_reports_assigned_user_id_users", "users", ["assigned_user_id"], ["id"])
        batch.create_index("ix_reports_assigned_user_id", ["assigned_user_id"])


def downgrade():
    with op.batch_alter_table("reports") as batch:
        batch.drop_index("ix_reports_assigned_user_id")
        batch.drop_constraint("fk_reports_assigned_user_id_users", type_="foreignkey")
        batch.drop_column("assigned_user_id")
