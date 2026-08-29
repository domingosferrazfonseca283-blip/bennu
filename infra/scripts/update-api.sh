#!/bin/sh
set -eu

APP_DIR="${BENNU_APP_DIR:-/opt/bennu}"

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
systemctl restart bennu-api
sleep 1
curl -fsS http://127.0.0.1:8000/health
printf '\nUpdate complete.\n'
