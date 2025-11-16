#!/bin/bash
# Clean up podman system - ignore errors if machine is not running
podman system prune -a -f 2>/dev/null || true
podman image prune -a -f 2>/dev/null || true
