#!/bin/sh
set -eu

APP_DIR="${BENNU_APP_DIR:-/opt/bennu}"
DATA_DIR="${BENNU_DATA_DIR:-/var/lib/bennu}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo sh infra/scripts/update-api.sh" >&2
  exit 1
fi

if [ ! -d "$APP_DIR/.git" ]; then
  echo "Bennu is not installed at $APP_DIR. Run install-api.sh first." >&2
  exit 1
fi

cd "$APP_DIR"
git fetch origin main
git checkout main
git reset --hard origin/main

python3 -m venv "$APP_DIR/.venv"
"$APP_DIR/.venv/bin/pip" install -r apps/api/requirements.txt

chown -R bennu:bennu "$APP_DIR"
su -s /bin/sh bennu -c "cd '$APP_DIR/apps/api' && '$APP_DIR/.venv/bin/alembic' upgrade head"

if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files >/dev/null 2>&1 && [ "$(ps -p 1 -o comm= 2>/dev/null || true)" = "systemd" ]; then
  systemctl restart bennu-api
else
  if [ -f "$DATA_DIR/api.pid" ]; then
    OLD_PID="$(cat "$DATA_DIR/api.pid" 2>/dev/null || true)"
    if [ -n "$OLD_PID" ]; then
      kill "$OLD_PID" 2>/dev/null || true
    fi
  fi
  mkdir -p "$DATA_DIR"
  su -s /bin/sh bennu -c "nohup '$APP_DIR/infra/scripts/run-api-portable.sh' > '$DATA_DIR/api.log' 2>&1 & echo \$! > '$DATA_DIR/api.pid'"
fi

sleep 3
curl -fsS http://127.0.0.1:8000/health
printf '\nUpdate complete.\n'
