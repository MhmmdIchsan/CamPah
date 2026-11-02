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
    migrate("upgrade", "head")
    engine = create_engine(url)
    inspector = inspect(engine)
    assert set(inspector.get_table_names()) == {"users", "reports", "report_status_history", "alembic_version"}
    assert {c["name"] for c in inspector.get_columns("reports")} >= {"ai_category", "deleted_at", "latitude", "longitude"}
    with engine.connect() as connection:
        assert connection.scalar(text("select version_num from alembic_version")) == "001_initial"
    engine.dispose()
    migrate("downgrade", "base")
    engine = create_engine(url)
    assert inspect(engine).get_table_names() == ["alembic_version"]
    engine.dispose()
    migrate("upgrade", "head")
