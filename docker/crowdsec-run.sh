#!/bin/bash
# runit service to start CrowdSec (LAPI enabled via config.yaml.local, agent disabled)
exec 2>&1
exec /usr/bin/crowdsec -c /etc/crowdsec/config.yaml
