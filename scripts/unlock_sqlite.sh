#!/bin/bash

DB_PATH="db/libreverse_development.sqlite3"
SHM_FILE="${DB_PATH}-shm"
WAL_FILE="${DB_PATH}-wal"

# Find and kill processes using the SQLite DB
PIDS=$(lsof | grep "$DB_PATH" | awk '{print $2}' | sort | uniq)
if [ -n "$PIDS" ]; then
    echo "Killing processes using $DB_PATH: $PIDS"
    for PID in $PIDS; do
        kill -9 $PID 2> /dev/null
    done
else
    echo "No processes using $DB_PATH found."
fi

# Remove lock files if they exist
for FILE in "$SHM_FILE" "$WAL_FILE"; do
    if [ -f "$FILE" ]; then
        echo "Removing $FILE"
        rm "$FILE"
    fi
done

echo "SQLite unlock complete."
