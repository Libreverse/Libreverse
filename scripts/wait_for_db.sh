#!/bin/bash
# wait_for_db.sh

# Wait until rails-db-creator is done
until [ -f /tmp/.db_creator_done.txt ]; do
    sleep 1
done

# Parse arguments for env vars and build command
command=()
for arg in "$@"; do
    if [[ $arg =~ ^[A-Z_]+=.+ ]]; then
        export "$arg"
    else
        command+=("$arg")
    fi
done

# Execute the command
exec "${command[@]}"