#!/bin/sh
set -eu

ROOT_DIR="${BENNU_APP_DIR:-$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}"
API_DIR="$ROOT_DIR/apps/api"
VENV="$ROOT_DIR/.venv"
DATA_DIR="${BENNU_DATA_DIR:-$ROOT_DIR/.bennu-data}"
PORT="${BENNU_API_PORT:-8000}"
HOST="${BENNU_API_HOST:-0.0.0.0}"

if [ ! -d "$VENV" ]; then
  python3 -m venv "$VENV"
fi
"$VENV/bin/python" -m pip install --upgrade pip
"$VENV/bin/pip" install -r "$API_DIR/requirements.txt"
mkdir -p "$DATA_DIR"
ln -sf "$DATA_DIR/bennu.db" "$API_DIR/bennu.db"

if [ -z "${BENNU_MOBILE_TOKEN:-}" ]; then
  if [ -f "$ROOT_DIR/.bennu-mobile-token" ]; then
    BENNU_MOBILE_TOKEN="$(cat "$ROOT_DIR/.bennu-mobile-token")"
  else
    BENNU_MOBILE_TOKEN="$($VENV/bin/python -c 'import secrets; print(secrets.token_urlsafe(32))')"
    umask 077
    printf '%s\n' "$BENNU_MOBILE_TOKEN" > "$ROOT_DIR/.bennu-mobile-token"
  fi
  export BENNU_MOBILE_TOKEN
fi

export DATABASE_URL="${DATABASE_URL:-sqlite:///$DATA_DIR/bennu.db}"
export BENNU_OWNER_EMAIL="${BENNU_OWNER_EMAIL:-}"

cd "$API_DIR"
"$VENV/bin/alembic" upgrade head
printf '\nBennu Core: http://%s:%s\n' "$HOST" "$PORT"
printf 'Mobile token stored in: %s/.bennu-mobile-token\n' "$ROOT_DIR"
printf 'Press Ctrl+C to stop.\n\n'
exec "$VENV/bin/python" -m uvicorn app.main:app --host "$HOST" --port "$PORT"
