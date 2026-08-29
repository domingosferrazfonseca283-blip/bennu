#!/bin/sh
set -eu

REPO_URL="${BENNU_REPO_URL:-https://github.com/domingosferrazfonseca283-blip/bennu.git}"
APP_DIR="${BENNU_APP_DIR:-/opt/bennu}"
DATA_DIR="${BENNU_DATA_DIR:-/var/lib/bennu}"
SERVICE="bennu-api"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo sh infra/scripts/install-api.sh" >&2
  exit 1
fi

install_packages() {
  if command -v dnf >/dev/null 2>&1; then
    dnf install -y git python3 python3-pip python3-devel gcc
  elif command -v apt-get >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y git python3 python3-venv python3-pip build-essential
  elif command -v yum >/dev/null 2>&1; then
    yum install -y git python3 python3-pip python3-devel gcc
  else
    echo "Unsupported package manager. Install git, Python 3 and pip manually." >&2
    exit 1
  fi
}

install_packages

if ! id bennu >/dev/null 2>&1; then
  useradd --system --home-dir "$APP_DIR" --create-home --shell /sbin/nologin bennu
fi

mkdir -p "$APP_DIR" "$DATA_DIR"
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

# Alembic uses the relative SQLite URL in alembic.ini, so run it from apps/api.
su -s /bin/sh bennu -c "cd '$APP_DIR/apps/api' && '$APP_DIR/.venv/bin/alembic' upgrade head"

install -m 0644 "$APP_DIR/infra/systemd/bennu-api.service" /etc/systemd/system/bennu-api.service
systemctl daemon-reload
systemctl enable --now "$SERVICE"

# Fedora/RHEL and Debian/Ubuntu both commonly use firewalld or ufw.
if command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state >/dev/null 2>&1; then
  firewall-cmd --permanent --add-port=8000/tcp || true
  firewall-cmd --reload || true
elif command -v ufw >/dev/null 2>&1; then
  ufw allow 8000/tcp || true
fi

sleep 1
curl -fsS http://127.0.0.1:8000/health
printf '\n\nBennu API installed. LAN addresses:\n'
ip -4 addr show scope global 2>/dev/null | awk '/inet / {print "  http://" $2}' | cut -d/ -f1 || true
printf '\nMobile URL: http://<SERVER-IP>:8000\n'
