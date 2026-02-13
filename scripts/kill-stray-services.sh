#!/usr/bin/env bash

# Script to kill stray development services by their port numbers
# This helps clean up processes that may be left running from previous dev sessions

set -e

PORTS=(
    3000  # dev-proxy (Caddy)
    3001
    3002  # webserver (Puma)
    3003  # websocket-server (AnyCable)
    50051 # websocket-server-rpc (AnyCable RPC)
    1025  # mail-receiver (SMTP)
    8025  # mail-receiver (HTTP)
    5173  # vite dev server
)

echo "Killing stray development services..."

for port in "${PORTS[@]}"; do
    # Find PIDs listening on this port
    pids=$(lsof -ti:$port 2>/dev/null || true)

    if [ -n "$pids" ]; then
        echo "Killing processes on port $port: $pids"
        # Try graceful kill first
        echo "$pids" | xargs kill -TERM 2>/dev/null || true
        # Wait a moment
        sleep 1
        # Force kill if still running
        echo "$pids" | xargs kill -KILL 2>/dev/null || true
    else
        echo "No processes found on port $port"
    fi
done

echo "Cleanup complete."
