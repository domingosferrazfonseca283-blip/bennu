#!/bin/sh
set -eu

# Bennu OS final installer for minimal Linux, containers and Termux-like environments.
# It never requires sudo and repairs an existing /opt/bennu checkout whose origin remote is missing.
REPO_URL="${BENNU_REPO_URL:-https://github.com/domingosferrazfonseca283-blip/bennu.git}"
APP_DIR="${BENNU_APP_DIR:-/opt/bennu}"
DATA_DIR="${BENNU_DATA_DIR:-/var/lib/bennu}"
ENV_DIR="${BENNU_ENV_DIR:-/etc/bennu}"
ENV_FILE="$ENV_DIR/bennu.env"
OWNER_EMAIL="${BENNU_OWNER_EMAIL:-domingosferrazfonseca283@gmail.com}"
PORT="${BENNU_API_PORT:-8000}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Execute como root: sh infra/scripts/finalize-install.sh" >&2
  exit 1
fi

if command -v apt-get >/dev/null 2>&1; then
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y git python3 python3-venv python3-pip build-essential curl
elif command -v dnf >/dev/null 2>&1; then
  dnf install -y git python3 python3-pip python3-devel gcc curl
elif command -v yum >/dev/null 2>&1; then
  yum install -y git python3 python3-pip python3-devel gcc curl
fi

mkdir -p "$DATA_DIR" "$ENV_DIR"

if [ -d "$APP_DIR/.git" ]; then
  if ! git -C "$APP_DIR" remote get-url origin >/dev/null 2>&1; then
    git -C "$APP_DIR" remote add origin "$REPO_URL"
  fi
  git -C "$APP_DIR" fetch origin main
  git -C "$APP_DIR" checkout main
  git -C "$APP_DIR" reset --hard origin/main
else
  if [ -e "$APP_DIR" ]; then
    mv "$APP_DIR" "${APP_DIR}.backup.$(date +%Y%m%d%H%M%S)"
  fi
  git clone "$REPO_URL" "$APP_DIR"
fi

if ! id bennu >/dev/null 2>&1; then
  useradd --system --home-dir "$APP_DIR" --create-home --shell /bin/sh bennu 2>/dev/null || true
fi

python3 -m venv "$APP_DIR/.venv"
"$APP_DIR/.venv/bin/python" -m pip install --upgrade pip
"$APP_DIR/.venv/bin/pip" install -r "$APP_DIR/apps/api/requirements.txt"

ln -sf "$DATA_DIR/bennu.db" "$APP_DIR/apps/api/bennu.db"

if [ ! -f "$ENV_FILE" ] || ! grep -q '^BENNU_MOBILE_TOKEN=' "$ENV_FILE" 2>/dev/null; then
  TOKEN="$($APP_DIR/.venv/bin/python -c 'import secrets; print(secrets.token_urlsafe(32))')"
  printf 'BENNU_MOBILE_TOKEN=%s\nBENNU_OWNER_EMAIL=%s\n' "$TOKEN" "$OWNER_EMAIL" > "$ENV_FILE"
  chmod 0600 "$ENV_FILE"
elif ! grep -q '^BENNU_OWNER_EMAIL=' "$ENV_FILE" 2>/dev/null; then
  printf 'BENNU_OWNER_EMAIL=%s\n' "$OWNER_EMAIL" >> "$ENV_FILE"
fi

chown -R bennu:bennu "$APP_DIR" "$DATA_DIR" 2>/dev/null || true

if command -v su >/dev/null 2>&1 && id bennu >/dev/null 2>&1; then
  su -s /bin/sh bennu -c "cd '$APP_DIR/apps/api' && BENNU_OWNER_EMAIL='$OWNER_EMAIL' '$APP_DIR/.venv/bin/alembic' upgrade head"
else
  cd "$APP_DIR/apps/api"
  BENNU_OWNER_EMAIL="$OWNER_EMAIL" "$APP_DIR/.venv/bin/alembic" upgrade head
fi

if command -v systemctl >/dev/null 2>&1 && [ "$(ps -p 1 -o comm= 2>/dev/null || true)" = "systemd" ]; then
  install -m 0644 "$APP_DIR/infra/systemd/bennu-api.service" /etc/systemd/system/bennu-api.service
  systemctl daemon-reload
  systemctl enable --now bennu-api
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
curl -fsS --max-time 5 "http://127.0.0.1:$PORT/health"
printf '\nBennu OS instalado.\nAPI: http://<IP-DO-SERVIDOR>:%s\nProprietario: %s\nToken privado: %s\n' "$PORT" "$OWNER_EMAIL" "$ENV_FILE"
printf 'Logs: %s/api.log\n' "$DATA_DIR"
