#!/bin/sh
set -eu

REPO_URL="${BENNU_REPO_URL:-https://github.com/domingosferrazfonseca283-blip/bennu.git}"
APP_DIR="${BENNU_APP_DIR:-/opt/bennu}"
DATA_DIR="${BENNU_DATA_DIR:-/var/lib/bennu}"
SERVICE="bennu-api"
ENV_DIR="/etc/bennu"
ENV_FILE="$ENV_DIR/bennu.env"
OWNER_EMAIL="${BENNU_OWNER_EMAIL:-domingosferrazfonseca283@gmail.com}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo sh infra/scripts/install-api.sh" >&2
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

if ! id bennu >/dev/null 2>&1; then
  useradd --system --home-dir "$APP_DIR" --create-home --shell /sbin/nologin bennu
fi

mkdir -p "$DATA_DIR" "$ENV_DIR"

# A previous portable installation may have left /opt/bennu without .git.
# Preserve it and install a clean repository checkout instead of attempting
# git operations in a non-repository directory.
if [ -d "$APP_DIR" ] && [ ! -d "$APP_DIR/.git" ]; then
  BACKUP_DIR="${APP_DIR}.backup.$(date +%Y%m%d%H%M%S)"
  mv "$APP_DIR" "$BACKUP_DIR"
  echo "Existing non-Git installation moved to $BACKUP_DIR"
fi

if [ ! -d "$APP_DIR/.git" ]; then
  git clone "$REPO_URL" "$APP_DIR"
else
  git -C "$APP_DIR" fetch origin main
  git -C "$APP_DIR" checkout main
  git -C "$APP_DIR" reset --hard origin/main
fi

chown -R bennu:bennu "$APP_DIR" "$DATA_DIR"

python3 -m venv "$APP_DIR/.venv"
"$APP_DIR/.venv/bin/python" -m pip install --upgrade pip
"$APP_DIR/.venv/bin/pip" install -r "$APP_DIR/apps/api/requirements.txt"

# Keep the database outside the Git working tree.
ln -sf "$DATA_DIR/bennu.db" "$APP_DIR/apps/api/bennu.db"
chown -h bennu:bennu "$APP_DIR/apps/api/bennu.db"

# Create the owner-controlled mobile gate once. Re-running the installer keeps it stable.
if [ ! -f "$ENV_FILE" ] || ! grep -q '^BENNU_MOBILE_TOKEN=' "$ENV_FILE" 2>/dev/null; then
  TOKEN="$($APP_DIR/.venv/bin/python -c 'import secrets; print(secrets.token_urlsafe(32))')"
  {
    printf 'BENNU_MOBILE_TOKEN=%s\n' "$TOKEN"
    printf 'BENNU_OWNER_EMAIL=%s\n' "$OWNER_EMAIL"
  } > "$ENV_FILE"
  chmod 0600 "$ENV_FILE"
elif ! grep -q '^BENNU_OWNER_EMAIL=' "$ENV_FILE" 2>/dev/null; then
  printf 'BENNU_OWNER_EMAIL=%s\n' "$OWNER_EMAIL" >> "$ENV_FILE"
  chmod 0600 "$ENV_FILE"
fi

# Alembic uses the relative SQLite URL in alembic.ini, so run it from apps/api.
su -s /bin/sh bennu -c "cd '$APP_DIR/apps/api' && '$APP_DIR/.venv/bin/alembic' upgrade head"

install -m 0644 "$APP_DIR/infra/systemd/bennu-api.service" /etc/systemd/system/bennu-api.service 2>/dev/null || true

if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files >/dev/null 2>&1 && [ "$(ps -p 1 -o comm= 2>/dev/null || true)" = "systemd" ]; then
  systemctl daemon-reload
  systemctl enable --now "$SERVICE"
else
  # Containers, Termux and minimal Linux images often do not run systemd.
  # Start the same API with the portable launcher instead.
  if command -v su >/dev/null 2>&1; then
    su -s /bin/sh bennu -c "nohup '$APP_DIR/infra/scripts/run-api-portable.sh' > '$DATA_DIR/api.log' 2>&1 & echo \$! > '$DATA_DIR/api.pid'"
  else
    nohup "$APP_DIR/infra/scripts/run-api-portable.sh" > "$DATA_DIR/api.log" 2>&1 &
    echo $! > "$DATA_DIR/api.pid"
  fi
fi

if command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state >/dev/null 2>&1; then
  firewall-cmd --permanent --add-port=8000/tcp || true
  firewall-cmd --reload || true
elif command -v ufw >/dev/null 2>&1; then
  ufw allow 8000/tcp || true
fi

sleep 3
if ! curl -fsS http://127.0.0.1:8000/health; then
  echo "Bennu API did not start. Check $DATA_DIR/api.log" >&2
  exit 1
fi

printf '\n\nBennu API installed. LAN addresses:\n'
ip -4 addr show scope global 2>/dev/null | awk '/inet / {print "  http://" $2}' | cut -d/ -f1 || true
printf '\nOwner:\n  %s\n' "$OWNER_EMAIL"
printf '\nPrivate mobile gate:\n  token provisioned in %s\n' "$ENV_FILE"
printf '\nMobile URL: http://<SERVER-IP>:8000\n'
