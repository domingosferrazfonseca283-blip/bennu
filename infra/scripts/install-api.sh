#!/bin/sh
set -eu

REPO_URL="${BENNU_REPO_URL:-https://github.com/domingosferrazfonseca283-blip/bennu.git}"
APP_DIR="${BENNU_APP_DIR:-/opt/bennu}"
DATA_DIR="${BENNU_DATA_DIR:-/var/lib/bennu}"
SERVICE="bennu-api"
ENV_DIR="${BENNU_ENV_DIR:-/etc/bennu}"
ENV_FILE="$ENV_DIR/bennu.env"
OWNER_EMAIL="${BENNU_OWNER_EMAIL:-domingosferrazfonseca283@gmail.com}"
PORT="${BENNU_API_PORT:-8000}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sh infra/scripts/install-api.sh" >&2
  exit 1
fi

install_packages() {
  if command -v dnf >/dev/null 2>&1; then
    dnf install -y git python3 python3-pip python3-devel gcc curl
  elif command -v apt-get >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y git python3 python3-venv python3-pip build-essential curl
  elif command -v yum >/dev/null 2>&1; then
    yum install -y git python3 python3-pip python3-devel gcc curl
  else
    echo "Unsupported package manager. Install git, Python 3 and pip manually." >&2
    exit 1
  fi
}

install_packages
mkdir -p "$DATA_DIR" "$ENV_DIR"

if ! id bennu >/dev/null 2>&1; then
  useradd --system --home-dir "$APP_DIR" --create-home --shell /bin/sh bennu 2>/dev/null || true
fi

# Repair or replace a previous installation. In particular, an existing .git
# directory without an origin remote must not make the installation fail.
if [ -d "$APP_DIR/.git" ]; then
  if ! git -C "$APP_DIR" remote get-url origin >/dev/null 2>&1; then
    git -C "$APP_DIR" remote add origin "$REPO_URL"
  fi
  git -C "$APP_DIR" fetch origin main
  git -C "$APP_DIR" checkout main
  git -C "$APP_DIR" reset --hard origin/main
else
  if [ -e "$APP_DIR" ]; then
    BACKUP_DIR="${APP_DIR}.backup.$(date +%Y%m%d%H%M%S)"
    mv "$APP_DIR" "$BACKUP_DIR"
    echo "Existing non-Git installation moved to $BACKUP_DIR"
  fi
  git clone "$REPO_URL" "$APP_DIR"
fi

chown -R bennu:bennu "$APP_DIR" "$DATA_DIR" 2>/dev/null || true

python3 -m venv "$APP_DIR/.venv"
"$APP_DIR/.venv/bin/python" -m pip install --upgrade pip
"$APP_DIR/.venv/bin/pip" install -r "$APP_DIR/apps/api/requirements.txt"

ln -sf "$DATA_DIR/bennu.db" "$APP_DIR/apps/api/bennu.db"

# One owner-controlled device gate. Keep it stable across upgrades.
if [ ! -f "$ENV_FILE" ] || ! grep -q '^BENNU_MOBILE_TOKEN=' "$ENV_FILE" 2>/dev/null; then
  TOKEN="$($APP_DIR/.venv/bin/python -c 'import secrets; print(secrets.token_urlsafe(32))')"
  printf 'BENNU_MOBILE_TOKEN=%s\nBENNU_OWNER_EMAIL=%s\n' "$TOKEN" "$OWNER_EMAIL" > "$ENV_FILE"
  chmod 0600 "$ENV_FILE"
elif ! grep -q '^BENNU_OWNER_EMAIL=' "$ENV_FILE" 2>/dev/null; then
  printf 'BENNU_OWNER_EMAIL=%s\n' "$OWNER_EMAIL" >> "$ENV_FILE"
  chmod 0600 "$ENV_FILE"
fi

if command -v su >/dev/null 2>&1 && id bennu >/dev/null 2>&1; then
  su -s /bin/sh bennu -c "cd '$APP_DIR/apps/api' && '$APP_DIR/.venv/bin/alembic' upgrade head"
else
  cd "$APP_DIR/apps/api"
  "$APP_DIR/.venv/bin/alembic" upgrade head
fi

install -m 0644 "$APP_DIR/infra/systemd/bennu-api.service" /etc/systemd/system/bennu-api.service 2>/dev/null || true

if command -v systemctl >/dev/null 2>&1 && [ "$(ps -p 1 -o comm= 2>/dev/null || true)" = "systemd" ]; then
  systemctl daemon-reload
  systemctl enable --now "$SERVICE"
else
  if [ -f "$DATA_DIR/api.pid" ]; then
    OLD_PID="$(cat "$DATA_DIR/api.pid" 2>/dev/null || true)"
    [ -z "$OLD_PID" ] || kill "$OLD_PID" 2>/dev/null || true
  fi
  if command -v su >/dev/null 2>&1 && id bennu >/dev/null 2>&1; then
    su -s /bin/sh bennu -c "nohup '$APP_DIR/infra/scripts/run-api-portable.sh' > '$DATA_DIR/api.log' 2>&1 & echo \$! > '$DATA_DIR/api.pid'"
  else
    nohup "$APP_DIR/infra/scripts/run-api-portable.sh" > "$DATA_DIR/api.log" 2>&1 &
    echo $! > "$DATA_DIR/api.pid"
  fi
fi

sleep 3
if ! curl -fsS --max-time 5 "http://127.0.0.1:$PORT/health"; then
  echo "Bennu API did not start. Check $DATA_DIR/api.log" >&2
  exit 1
fi

printf '\nBennu API installed.\nAPI: http://<SERVER-IP>:%s\nOwner: %s\nPrivate mobile gate: %s\nLogs: %s/api.log\n' "$PORT" "$OWNER_EMAIL" "$ENV_FILE" "$DATA_DIR"
