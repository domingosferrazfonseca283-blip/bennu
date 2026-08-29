#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
API_DIR="$ROOT_DIR/apps/api"
PYTHON_BIN="${PYTHON_BIN:-python3}"
HOST="${BENNU_API_HOST:-0.0.0.0}"
PORT="${BENNU_API_PORT:-8000}"

cd "$API_DIR"

if [ ! -d .venv ]; then
  "$PYTHON_BIN" -m venv .venv
fi

. .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python -m alembic upgrade head
exec python -m uvicorn app.main:app --host "$HOST" --port "$PORT"
