#!/bin/bash
set -euo pipefail
exec 2>&1

# wait for CrowdSec LAPI to be healthy, then bootstrap bouncer
for i in $(seq 1 60); do
  if cscli lapi status >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

/home/app/webapp/docker/crowdsec-bootstrap.sh || true

exit 0
