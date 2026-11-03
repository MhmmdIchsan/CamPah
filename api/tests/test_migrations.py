import os
from pathlib import Path
import subprocess
import sys

from sqlalchemy import create_engine, inspect, text

API_ROOT = Path(__file__).resolve().parents[1]


def test_migration_round_trip(tmp_path):
    url = f"sqlite:///{(tmp_path / 'migration.db').as_posix()}"
    environment = {**os.environ, "DATABASE_URL": url}
    def migrate(*command):
        subprocess.run([sys.executable, "-m", "alembic", *command], cwd=API_ROOT, env=environment, check=True, capture_output=True, text=True)
    migrate("upgrade", "001_initial")
    engine = create_engine(url)
    with engine.begin() as connection:
        connection.execute(text("INSERT INTO report_status_history (id, report_id, admin_id, old_status, new_status, changed_at) VALUES (1, 1, 1, 'Pending', 'Completed', '2026-01-01')"))
    engine.dispose()
    migrate("upgrade", "head")
    engine = create_engine(url)
    inspector = inspect(engine)
    assert set(inspector.get_table_names()) == {"users", "reports", "report_status_history", "alembic_version"}
    assert {c["name"] for c in inspector.get_columns("reports")} >= {"ai_category", "deleted_at", "latitude", "longitude"}
    with engine.connect() as connection:
        assert connection.scalar(text("select version_num from alembic_version")) == "002_followup"
        old_row = connection.execute(text("select note, is_correction from report_status_history where id = 1")).one()
        assert old_row.note is None and not old_row.is_correction
    assert {c["name"] for c in inspector.get_columns("report_status_history")} >= {"note", "is_correction"}
    engine.dispose()
    migrate("downgrade", "base")
    engine = create_engine(url)
    assert inspect(engine).get_table_names() == ["alembic_version"]
    engine.dispose()
    migrate("upgrade", "head")
