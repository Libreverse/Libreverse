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
    echo "LD_PRELOAD=$JEMALLOC_PATH" >>/etc/environment

    # Configure jemalloc for optimal performance
    export MALLOC_CONF="dirty_decay_ms:1000,muzzy_decay_ms:1000,background_thread:true,abort_conf:true"
    echo "MALLOC_CONF=$MALLOC_CONF" >>/etc/environment

    echo "✓ jemalloc enabled system-wide: $JEMALLOC_PATH"
else
    echo "⚠ jemalloc not found, using system malloc"
fi

# Database Migration Step
echo "🗄️ Running database migrations..."

# Change to webapp directory
cd /home/app/webapp

# Set Rails environment to production
export RAILS_ENV=production

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

echo "  � Checking migration status for all databases..."

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
chmod -R 664 /home/app/webapp/log/ 2>/dev/null || true

echo "✅ File permissions configured"

# Bootstrap CrowdSec bouncer key from Rails secrets if CrowdSec is present
if [ -x /home/app/webapp/docker/crowdsec-bootstrap.sh ]; then
    echo "🛡️  Bootstrapping CrowdSec bouncer configuration..."
    /home/app/webapp/docker/crowdsec-bootstrap.sh || true
fi

# Generate Passenger pool sizing based on ThreadBudget (app_threads maps to process count in OSS Passenger)
echo "🧮 Generating Passenger pool sizing from ThreadBudget..."
mkdir -p /etc/nginx/conf.d

# Use Ruby to evaluate ThreadBudget and output app_threads
APP_PROC_TARGET=$(bundle exec ruby -e 'begin; require "./config/thread_budget"; b=ThreadBudget.compute; puts b[:app_threads].to_i; rescue => e; warn e.message; puts 0; end' 2>/dev/null)

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

cat >/etc/nginx/conf.d/99-passenger-pool.conf <<EOF
# Autogenerated at container start by entrypoint-with-jemalloc.sh
# In Passenger OSS, one request per process; align processes with ThreadBudget app_threads
passenger_max_pool_size $APP_PROC_TARGET;
passenger_min_instances $APP_PROC_TARGET;
# Keep per-app cap equal to pool size for single-app container
passenger_max_instances_per_app $APP_PROC_TARGET;
EOF

echo "  ➜ passenger_max_pool_size/min_instances set to $APP_PROC_TARGET"

# Configure Passenger prestart to warm processes.
# Build a correct URL: scheme + server_name + :port + path
SERVER_NAME_CONF=$(awk '/server_name/{print $2}' /etc/nginx/sites-enabled/webapp.conf | tr -d ';' | head -n1)
LISTEN_PORT=$(awk '/listen /{print $2}' /etc/nginx/sites-enabled/webapp.conf | tr -d ';' | tr -d 'reuseport' | head -n1)
SCHEME=${PASSENGER_PRESTART_SCHEME:-"http"}
HOST=${PASSENGER_PRESTART_HOST:-"${SERVER_NAME_CONF:-libreverse}"}
PORT=${PASSENGER_PRESTART_PORT:-"${LISTEN_PORT:-3000}"}
PATH_PART=${PASSENGER_PRESTART_PATH:-"/"}
PRESTART_URL=${PASSENGER_PRESTART_URL:-"${SCHEME}://${HOST}:${PORT}${PATH_PART}"}

cat >/etc/nginx/conf.d/20-passenger-prestart.conf <<EOF
# Autogenerated at container start
passenger_pre_start $PRESTART_URL;
EOF
echo "  ➜ passenger_pre_start set to $PRESTART_URL"

exec /sbin/my_init
