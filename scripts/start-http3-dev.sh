#!/bin/bash
set -euo pipefail

# === CONFIG ===
APP_PORT="${APP_PORT:-3002}"     # Your dev app (e.g., Rails, React)
CADDY_PORT="${CADDY_PORT:-3000}" # HTTPS + HTTP/3 port
CERT_DIR="/tmp/mkcert-dev-certs"
CERT="$CERT_DIR/localhost.pem"
KEY="$CERT_DIR/localhost-key.pem"
CADDYFILE="Caddyfile"

# === Cleanup on exit ===
cleanup() {
    rm -rf "$CERT_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# === 1. Generate certs in /tmp (non-sudo) ===
mkdir -p "$CERT_DIR"

if [ ! -f "$CERT" ] || [ ! -f "$KEY" ]; then
    mkcert -cert-file "$CERT" -key-file "$KEY" localhost 127.0.0.1 ::1
    chmod 600 "$KEY"
fi

echo "📡 Starting Caddy on https://localhost:$CADDY_PORT → localhost:$APP_PORT"

# === 3. Start Caddy (with HTTP/3) ===
caddy run --config "$CADDYFILE" --adapter caddyfile