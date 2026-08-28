#!/usr/bin/env bash
set -euo pipefail

PREFIX="${BENNU_PREFIX:-$HOME/.local/share/bennu}"
BIN_DIR="${BENNU_BIN_DIR:-$HOME/.local/bin}"
mkdir -p "$PREFIX" "$BIN_DIR"

cat > "$BIN_DIR/bennu" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exec python3 -m bennu_cli "$@"
EOF
chmod +x "$BIN_DIR/bennu"

echo "Bennu bootstrap installed at $BIN_DIR/bennu"
echo "This bootstrap does not grant administrative access; Owner authentication remains enforced by the platform."
