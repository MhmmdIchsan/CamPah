"""Apply migrations, then start the API. Run from any working directory."""
import os
from pathlib import Path
import subprocess
import sys

os.chdir(Path(__file__).resolve().parent)
subprocess.run([sys.executable, "-m", "alembic", "upgrade", "head"], check=True)
subprocess.run([sys.executable, "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", os.getenv("PORT", "8000")], check=True)
