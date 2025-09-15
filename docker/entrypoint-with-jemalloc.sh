#!/bin/bash
# Entrypoint: run ALL processes with mimalloc for maximum memory optimization

# Detect mimalloc library path for current architecture (robust across releases)
MIMALLOC_PATH=""
if [ -f /usr/lib/x86_64-linux-gnu/libmimalloc.so.2 ]; then
    MIMALLOC_PATH="/usr/lib/x86_64-linux-gnu/libmimalloc.so.2"
elif [ -f /usr/lib/aarch64-linux-gnu/libmimalloc.so.2 ]; then
    MIMALLOC_PATH="/usr/lib/aarch64-linux-gnu/libmimalloc.so.2"
else
    # Try ldconfig cache first
    if command -v ldconfig >/dev/null 2>&1; then
        CANDIDATE=$(ldconfig -p 2>/dev/null | awk '/libmimalloc\.so/{print $4; exit}')
        if [ -n "$CANDIDATE" ] && [ -f "$CANDIDATE" ]; then
            MIMALLOC_PATH="$CANDIDATE"
        fi
    fi
    # Fallback to filesystem search
    if [ -z "$MIMALLOC_PATH" ]; then
        CANDIDATE=$(find /usr/lib /lib -type f -name 'libmimalloc.so*' 2>/dev/null | head -n1)
        if [ -n "$CANDIDATE" ] && [ -f "$CANDIDATE" ]; then
            MIMALLOC_PATH="$CANDIDATE"
        fi
    fi
fi

if [ -n "$MIMALLOC_PATH" ]; then
    # Set mimalloc globally for all processes in the container
    export LD_PRELOAD="$MIMALLOC_PATH"

    # Also write to /etc/environment for system-wide availability
    echo "LD_PRELOAD=$MIMALLOC_PATH" >>/etc/environment

    # Configure mimalloc for optimal performance as requested
    export MIMALLOC_LARGE_OS_PAGES=1
    export MIMALLOC_EAGER_COMMIT=1
    export MIMALLOC_SEGMENT_CACHE=1
    {
        echo "MIMALLOC_LARGE_OS_PAGES=$MIMALLOC_LARGE_OS_PAGES"
        echo "MIMALLOC_EAGER_COMMIT=$MIMALLOC_EAGER_COMMIT"
        echo "MIMALLOC_SEGMENT_CACHE=$MIMALLOC_SEGMENT_CACHE"
    } >>/etc/environment

    # Ensure env vars propagate to runit services via my_init
    mkdir -p /etc/container_environment
    printf %s "$MIMALLOC_PATH" >/etc/container_environment/LD_PRELOAD
    printf %s "$MIMALLOC_LARGE_OS_PAGES" >/etc/container_environment/MIMALLOC_LARGE_OS_PAGES
    printf %s "$MIMALLOC_EAGER_COMMIT" >/etc/container_environment/MIMALLOC_EAGER_COMMIT
    printf %s "$MIMALLOC_SEGMENT_CACHE" >/etc/container_environment/MIMALLOC_SEGMENT_CACHE

    echo "✓ mimalloc enabled system-wide: $MIMALLOC_PATH"
else
    echo "⚠ mimalloc not found, using system malloc"
fi

# Database Migration Step
echo "🗄️ Running database migrations..."

# Change to webapp directory
cd /home/app/webapp

# Ensure Bundler can always find the Gemfile; RAILS_ENV is set at build/runtime
export BUNDLE_GEMFILE=/home/app/webapp/Gemfile

# Propagate env to all child processes managed by my_init (phusion baseimage)
mkdir -p /etc/container_environment
printf %s "$BUNDLE_GEMFILE" >/etc/container_environment/BUNDLE_GEMFILE
printf %s "${RAILS_ENV:-production}" >/etc/container_environment/RAILS_ENV

# passenger_file_descriptor_log_file is no longer configured in the image; nothing to strip here

# Function to run migrations safely with comprehensive error handling
run_migrations() {
    local command=$1
    local description=$2
    local skip_on_error=${3:-false}

    echo "  📊 Migrating $description..."

    # Capture both stdout and stderr
    local output
    local exit_code

    output=$(bin/rails $command 2>&1)
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo "  ✅ $description migration completed successfully"
        # Show relevant output if there were actual migrations
        if echo "$output" | grep -q "Migrating\|migrated"; then
            echo "$output" | grep "Migrating\|migrated" | sed 's/^/    /'
        fi
    else
        if echo "$output" | grep -q "No migrations to run\|already migrated\|up to date"; then
            echo "  ℹ️ $description is already up to date"
        elif echo "$output" | grep -q "does not exist\|no such table\|database.*doesn't exist"; then
            echo "  🔧 $description needs setup, running db:setup..."
            # Try to setup the database first
            local setup_command=${command/migrate/setup}
            local setup_output
            setup_output=$(bin/rails $setup_command 2>&1)
            if [ $? -eq 0 ]; then
                echo "  ✅ $description setup completed successfully"
            else
                echo "  ⚠️ $description setup failed"
                if [ "$skip_on_error" = "false" ]; then
                    echo "$setup_output" | sed 's/^/    /'
                fi
            fi
        else
            echo "  ⚠️ $description migration failed"
            if [ "$skip_on_error" = "false" ]; then
                echo "$output" | sed 's/^/    /'
            fi
        fi
    fi
}

# Function to check database status
check_migration_status() {
    local command=$1
    local description=$2

    echo "  📋 Checking $description migration status..."
    local status_output
    status_output=$(bin/rails $command 2>&1)

    if [ $? -eq 0 ]; then
        # Count pending migrations
        local pending_count
        pending_count=$(echo "$status_output" | grep -c " down ")

        if [ "$pending_count" -gt 0 ]; then
            echo "  📈 $description has $pending_count pending migration(s)"
        else
            echo "  ✅ $description is up to date"
        fi
    else
        echo "  ❓ Could not check $description status (database may not exist yet)"
    fi
}

echo "  🔎 Checking migration status for all databases..."

# Check migration status first
check_migration_status "db:migrate:status" "Primary database"
check_migration_status "db:migrate:status:cache" "Cache database"
check_migration_status "db:migrate:status:queue" "Queue tables (same DB, different migrations)"

echo "  🔄 Running migrations for all databases..."

# Primary database migrations (critical - don't skip errors)
run_migrations "db:migrate" "Primary database" false

# Cache database migrations (Solid Cache) - critical for caching
# This uses a separate SQLite database
run_migrations "db:migrate:cache" "Cache database (Solid Cache)" false

# Queue table migrations (Solid Queue) - critical for background jobs
# This uses the same database as primary but creates separate tables
run_migrations "db:migrate:queue" "Queue tables (Solid Queue)" false

# Cable database migrations (Action Cable) - less critical, can skip errors
if grep -q "cable:" /home/app/webapp/config/database.yml 2>/dev/null; then
    run_migrations "db:migrate:cable" "Cable database (Action Cable)" true
else
    echo "  ℹ️ Cable database not configured, skipping"
fi

echo "✅ Database migration step completed"

# Database Seeding Step
echo "🌱 Running database seeds..."
seed_output=$(bin/rails db:seed 2>&1)
if [ $? -eq 0 ]; then
    echo "  ✅ Database seeds applied"
    echo "$seed_output" | grep -E "created|updated|seed" | sed 's/^/    /' || true
else
    if echo "$seed_output" | grep -qi "nothing to seed"; then
        echo "  ℹ️ No seeds to apply"
    else
        echo "  ⚠️ Database seeding failed"
        echo "$seed_output" | sed 's/^/    /'
    fi
fi

# Fix permissions for SQLite databases
echo "🔧 Setting proper permissions for SQLite databases..."
chown -R app:app /home/app/webapp/db/
chmod -R 664 /home/app/webapp/db/*.sqlite3 2>/dev/null || true
chmod -R 775 /home/app/webapp/db/ 2>/dev/null || true

# Also ensure log directory is writable
echo "📝 Setting up log directory permissions..."
mkdir -p /home/app/webapp/log
chown -R app:app /home/app/webapp/log/
chmod -R 775 /home/app/webapp/log/ 2>/dev/null || true
touch /home/app/webapp/log/production.log
chown app:app /home/app/webapp/log/production.log
chmod 664 /home/app/webapp/log/production.log

echo "✅ File permissions configured"

# Bootstrap CrowdSec bouncer key from Rails secrets if CrowdSec is present
if [ -x /home/app/webapp/docker/crowdsec-bootstrap.sh ]; then
    echo "🛡️  Bootstrapping CrowdSec bouncer configuration..."
    /home/app/webapp/docker/crowdsec-bootstrap.sh || true
fi

# Generate web split (Passenger + Nginx) sizing based on ThreadBudget
echo "🧮 Generating web split (Passenger + Nginx) from ThreadBudget..."
mkdir -p /etc/nginx/conf.d

# Use Ruby to evaluate ThreadBudget and output passenger/nginx targets
read APP_PROC_TARGET NGINX_WORKERS < <(bundle exec ruby -e 'begin; require "./config/thread_budget"; b=ThreadBudget.compute; printf("%d %d\n", b[:passenger_procs].to_i, b[:nginx_workers].to_i); rescue => e; warn e.message; puts "0 0"; end' 2>/dev/null)

if [ -z "$APP_PROC_TARGET" ] || [ "$APP_PROC_TARGET" -le 0 ]; then
    if command -v nproc >/dev/null 2>&1; then
        APP_PROC_TARGET=$(nproc)
    else
        APP_PROC_TARGET=2
    fi
fi

# Clamp to sensible bounds
if [ "$APP_PROC_TARGET" -lt 1 ]; then APP_PROC_TARGET=1; fi
if [ "$APP_PROC_TARGET" -gt 64 ]; then APP_PROC_TARGET=64; fi
if [ -z "$NGINX_WORKERS" ] || [ "$NGINX_WORKERS" -lt 1 ]; then
    if command -v nproc >/dev/null 2>&1; then
        NGINX_WORKERS=1
    else
        NGINX_WORKERS=1
    fi
fi

cat >/etc/nginx/conf.d/99-passenger-pool.conf <<EOF
# Autogenerated at container start by entrypoint-with-mimalloc.sh
# In Passenger OSS, one request per process; align processes with ThreadBudget app_threads
passenger_max_pool_size $APP_PROC_TARGET;
# Keep initial warm processes low to avoid cold-boot contention
passenger_min_instances 1;
# Keep per-app cap equal to pool size for single-app container
passenger_max_instances_per_app $APP_PROC_TARGET;
EOF

echo "  ➜ passenger_max_pool_size set to $APP_PROC_TARGET; passenger_min_instances=1"

# Generate Nginx worker_processes drop-in in main context
cat >/etc/nginx/worker_processes.conf <<EOF
# Autogenerated at container start by entrypoint
worker_processes $NGINX_WORKERS;
EOF
echo "  ➜ nginx worker_processes set to $NGINX_WORKERS (in /etc/nginx/worker_processes.conf)"

# Configure Passenger prestart to warm processes.
# Build a correct URL: scheme + host + :port + path
# Ignore commented lines and extract settings from active directives.
SERVER_NAME_CONF=$(awk '/^[[:space:]]*server_name[[:space:]]/ {for (i=2;i<=NF;i++){gsub(/;$/,"",$i); if ($i!="") {print $i; exit}}}' /etc/nginx/sites-enabled/webapp.conf | head -n1)
LISTEN_PORT=$(awk '/^[[:space:]]*listen[[:space:]]/ {for (i=2;i<=NF;i++){gsub(/;$/,"",$i); if ($i ~ /^[0-9]+$/) {print $i; exit}}}' /etc/nginx/sites-enabled/webapp.conf | head -n1)
BASE_URI=$(awk '/^[[:space:]]*passenger_base_uri[[:space:]]/ {for (i=2;i<=NF;i++){gsub(/;$/,"",$i); if ($i!="") {print $i; exit}}}' /etc/nginx/sites-enabled/webapp.conf | head -n1)

SCHEME=${PASSENGER_PRESTART_SCHEME:-"http"}

# Prefer explicit env, then INSTANCE_DOMAIN, then Rails detection, then server_name, then localhost
HOST=${PASSENGER_PRESTART_HOST:-}
if [ -z "$HOST" ]; then
    HOST=${INSTANCE_DOMAIN:-}
fi
if [ -z "$HOST" ]; then
    HOST=$(bundle exec ruby -e 'begin; require "./config/application"; Rails.application.initialize!; d = LibreverseInstance.instance_domain rescue nil; puts d if d; rescue => e; warn e.message; end' 2>/dev/null | head -n1)
fi
if [ -z "$HOST" ]; then
    HOST=${SERVER_NAME_CONF:-}
fi
if [ -z "$HOST" ]; then
    HOST="127.0.0.1"
fi

PORT=${PASSENGER_PRESTART_PORT:-"${LISTEN_PORT:-3000}"}

PATH_PART=${PASSENGER_PRESTART_PATH:-"${BASE_URI:-/}"}
PRESTART_URL=${PASSENGER_PRESTART_URL:-"${SCHEME}://${HOST}:${PORT}${PATH_PART}"}

# Write prestart directives
validate_url() { echo "$1" | grep -Eq '^https?://[^/:]+:[0-9]+(/|$)'; }

if [ -n "${PASSENGER_PRESTART_URL:-}" ]; then
    if validate_url "$PASSENGER_PRESTART_URL"; then
        printf "# Autogenerated at container start (env override)\npassenger_pre_start %s;\n" "$PASSENGER_PRESTART_URL" \
            >/etc/nginx/conf.d/20-passenger-prestart.conf
        echo "  ➜ passenger_pre_start set to $PASSENGER_PRESTART_URL (env)"
    else
        echo "  ⚠️ PASSENGER_PRESTART_URL invalid: $PASSENGER_PRESTART_URL"
    fi
else
    LOCAL_URL="http://127.0.0.1:${PORT}/"
    CONF_URL="${SCHEME}://${HOST}:${PORT}${PATH_PART}"
    {
        echo "# Autogenerated at container start (multi)"
        if validate_url "$LOCAL_URL"; then
            echo "passenger_pre_start $LOCAL_URL;"
        fi
        if [ "$HOST" != "127.0.0.1" ] && validate_url "$CONF_URL"; then
            echo "passenger_pre_start $CONF_URL;"
        fi
    } >/etc/nginx/conf.d/20-passenger-prestart.conf

    # Log what we set (stdout only)
    if validate_url "$LOCAL_URL"; then
        echo "  ➜ passenger_pre_start set to $LOCAL_URL"
    else
        echo "  ⚠️ Skipping invalid local URL: $LOCAL_URL" >&2
    fi
    if [ "$HOST" != "127.0.0.1" ] && validate_url "$CONF_URL"; then
        echo "  ➜ passenger_pre_start set to $CONF_URL"
    fi
fi

exec /sbin/my_init
