#!/bin/bash
set -euo pipefail

# Only run if CrowdSec binaries exist
if ! command -v cscli >/dev/null 2>&1 || ! command -v crowdsec >/dev/null 2>&1; then
  exit 0
fi

# Wait for LAPI to be listening on 127.0.0.1:8080 (as configured)
for i in $(seq 1 60); do
  if cscli lapi status >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

/home/app/webapp/docker/crowdsec-bootstrap.sh || true

exit 0
