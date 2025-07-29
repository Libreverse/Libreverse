#!/bin/bash
# Entrypoint: run ALL processes with jemalloc for maximum memory optimization

# Detect jemalloc library path for current architecture
JEMALLOC_PATH=""
if [ -f /usr/lib/x86_64-linux-gnu/libjemalloc.so.2 ]; then
    JEMALLOC_PATH="/usr/lib/x86_64-linux-gnu/libjemalloc.so.2"
elif [ -f /usr/lib/aarch64-linux-gnu/libjemalloc.so.2 ]; then
    JEMALLOC_PATH="/usr/lib/aarch64-linux-gnu/libjemalloc.so.2"
fi

if [ -n "$JEMALLOC_PATH" ]; then
    # Set jemalloc globally for all processes in the container
    export LD_PRELOAD="$JEMALLOC_PATH"

    # Also write to /etc/environment for system-wide availability
    echo "LD_PRELOAD=$JEMALLOC_PATH" >> /etc/environment

    # Configure jemalloc for optimal performance
    export MALLOC_CONF="dirty_decay_ms:1000,muzzy_decay_ms:1000,background_thread:true,abort_conf:true"
    echo "MALLOC_CONF=$MALLOC_CONF" >> /etc/environment

    echo "✓ jemalloc enabled system-wide: $JEMALLOC_PATH"
else
    echo "⚠ jemalloc not found, using system malloc"
fi

exec /sbin/my_init
