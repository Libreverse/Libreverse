#!/bin/bash
# Bootstrap CrowdSec NGINX bouncer API key using Rails master key (deterministic)
set -euo pipefail

# If CrowdSec isn't installed, silently no-op
if ! command -v cscli >/dev/null 2>&1 || ! command -v crowdsec >/dev/null 2>&1; then
    exit 0
fi

BOUNCER_DIR=/etc/crowdsec/bouncers
CONF="$BOUNCER_DIR/crowdsec-nginx-bouncer.conf"
mkdir -p "$BOUNCER_DIR"

# Prefer explicit CROWDSEC_LAPI_URL, else default to local LAPI
API_URL_DEFAULT="${CROWDSEC_LAPI_URL:-http://127.0.0.1:8080}"

# Derive a deterministic key from Rails secrets if available
if [ -n "${RAILS_MASTER_KEY:-}" ]; then
    SEED="$RAILS_MASTER_KEY"
elif [ -n "${SECRET_KEY_BASE:-}" ]; then
    SEED="$SECRET_KEY_BASE"
else
    # No deterministic seed available; do not proceed to avoid flapping keys
    exit 0
fi

# Compute a stable hex key (alphanumeric) from the seed
if command -v sha256sum >/dev/null 2>&1; then
    KEY=$(printf "libreverse-nginx-bouncer:%s" "$SEED" | sha256sum | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
    KEY=$(printf "libreverse-nginx-bouncer:%s" "$SEED" | shasum -a 256 | awk '{print $1}')
else
    # Fallback to md5sum; still deterministic but shorter security margin
    if command -v md5sum >/dev/null 2>&1; then
        KEY=$(printf "libreverse-nginx-bouncer:%s" "$SEED" | md5sum | awk '{print $1}')
    else
        # Last resort: generate a random alnum key (non-deterministic)
        KEY=$(head -c 32 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 32)
    fi
fi

# Ensure main config contains API URL and API KEY
touch "$CONF"

# Replace templated placeholders if present
if grep -q '<API_KEY>' "$CONF" 2>/dev/null || grep -q '<LAPI_URL>' "$CONF" 2>/dev/null; then
    TMP=$(mktemp)
    API_KEY="$KEY" CROWDSEC_LAPI_URL="$API_URL_DEFAULT" envsubst '$API_KEY $CROWDSEC_LAPI_URL' < "$CONF" > "$TMP"
    cat "$TMP" > "$CONF"
    rm -f "$TMP"
fi

# Ensure key=value pairs are present (idempotent)
if grep -q '^API_URL=' "$CONF" 2>/dev/null; then
    sed -i "s#^API_URL=.*#API_URL=$API_URL_DEFAULT#" "$CONF" || true
else
    echo "API_URL=$API_URL_DEFAULT" >> "$CONF"
fi
if grep -q '^API_KEY=' "$CONF" 2>/dev/null; then
    sed -i "s#^API_KEY=.*#API_KEY=$KEY#" "$CONF" || true
else
    echo "API_KEY=$KEY" >> "$CONF"
fi

    # Enforce deny-only, no-captcha, no-appsec settings at runtime
    sed -i "/^CAPTCHA_/d" "$CONF" 2>/dev/null || true
    sed -i "/^RECAPTCHA_/d" "$CONF" 2>/dev/null || true
    sed -i "/^HCAPTCHA_/d" "$CONF" 2>/dev/null || true
    sed -i "/^BOUNCER_MODE=/d" "$CONF" 2>/dev/null || true
    sed -i "/^DISABLE_CAPTCHA=/d" "$CONF" 2>/dev/null || true
    grep -q '^CAPTCHA_PROVIDER=' "$CONF" 2>/dev/null && sed -i 's/^CAPTCHA_PROVIDER=.*/CAPTCHA_PROVIDER=none/' "$CONF" || echo 'CAPTCHA_PROVIDER=none' >> "$CONF"
    grep -q '^FALLBACK_REMEDIATION=' "$CONF" 2>/dev/null && sed -i 's/^FALLBACK_REMEDIATION=.*/FALLBACK_REMEDIATION=ban/' "$CONF" || echo 'FALLBACK_REMEDIATION=ban' >> "$CONF"
    grep -q '^ALWAYS_SEND_TO_APPSEC=' "$CONF" 2>/dev/null && sed -i 's/^ALWAYS_SEND_TO_APPSEC=.*/ALWAYS_SEND_TO_APPSEC=false/' "$CONF" || echo 'ALWAYS_SEND_TO_APPSEC=false' >> "$CONF"
    grep -q '^APPSEC_URL=' "$CONF" 2>/dev/null && sed -i 's#^APPSEC_URL=.*#APPSEC_URL=#' "$CONF" || echo 'APPSEC_URL=' >> "$CONF"
    grep -q '^REDIRECT_LOCATION=' "$CONF" 2>/dev/null && sed -i 's#^REDIRECT_LOCATION=.*#REDIRECT_LOCATION=#' "$CONF" || echo 'REDIRECT_LOCATION=' >> "$CONF"
    grep -q '^ENABLED=' "$CONF" 2>/dev/null && sed -i 's/^ENABLED=.*/ENABLED=true/' "$CONF" || echo 'ENABLED=true' >> "$CONF"
    grep -q '^MODE=' "$CONF" 2>/dev/null && sed -i 's/^MODE=.*/MODE=stream/' "$CONF" || echo 'MODE=stream' >> "$CONF"

# Wait for LAPI to be ready (up to ~30s)
for i in $(seq 1 30); do
    if cscli lapi status >/dev/null 2>&1; then
        READY=1
        break
    fi
    sleep 1
done

# If LAPI still not ready, leave the config in place and exit gracefully
if ! cscli lapi status >/dev/null 2>&1; then
    exit 0
fi

# Register the bouncer if missing. Prefer setting our deterministic KEY.
if cscli bouncers list 2>/dev/null | grep -qE '^\s*nginx\s'; then
    :
else
    # Try with explicit key (supported on recent cscli). If it fails, fallback to auto-generated key.
    if cscli bouncers add nginx --key "$KEY" >/dev/null 2>&1; then
        :
    else
        NEWKEY=$(cscli bouncers add nginx -o raw 2>/dev/null | tail -n1 | tr -d '[:space:]')
        if [ -n "$NEWKEY" ]; then
            # Persist the server-generated key instead
            if grep -q '^API_KEY=' "$CONF"; then
                sed -i "s/^API_KEY=.*/API_KEY=$NEWKEY/" "$CONF" || true
            else
                echo "API_KEY=$NEWKEY" >> "$CONF"
            fi
        fi
    fi
fi

exit 0
