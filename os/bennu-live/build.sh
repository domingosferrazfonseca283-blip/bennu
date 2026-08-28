#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${OUT_DIR:-${ROOT_DIR}/../artifacts}"
mkdir -p "$OUT_DIR"

if ! command -v lb >/dev/null 2>&1; then
  echo "live-build is required; install it on a Debian-based build host." >&2
  exit 1
fi

cd "$ROOT_DIR"
rm -rf work
mkdir -p work
cd work

lb config \
  --distribution bookworm \
  --binary-images iso-hybrid \
  --debian-installer live \
  --archive-areas "main contrib non-free-firmware" \
  --apt-recommends true \
  --linux-packages "linux-image" \
  --bootappend-live "boot=live components hostname=bennu-os" \
  --debootstrap-options "--variant=minbase"

mkdir -p config/package-lists config/includes.chroot/etc/systemd/system
cp "$ROOT_DIR/packages.txt" config/package-lists/bennu.list.chroot
cp "$ROOT_DIR/systemd/bennu-dashboard.service" config/includes.chroot/etc/systemd/system/bennu-dashboard.service

lb build
mv live-image-*.hybrid.iso "$OUT_DIR/bennu-os-bookworm-amd64.iso"
sha256sum "$OUT_DIR/bennu-os-bookworm-amd64.iso" > "$OUT_DIR/bennu-os-bookworm-amd64.iso.sha256"

echo "ISO created at $OUT_DIR/bennu-os-bookworm-amd64.iso"
