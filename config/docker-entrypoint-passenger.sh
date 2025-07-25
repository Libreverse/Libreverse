#!/bin/bash
set -e

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting Libreverse with Passenger + nginx"

# Ensure nginx directories exist and have correct permissions
mkdir -p /var/log/nginx /var/lib/nginx /run/nginx
chown -R www-data:www-data /var/log/nginx /var/lib/nginx /run/nginx

# Prepare the database (run as rails user)
log "Preparing database..."
su rails -c "cd /rails && bundle exec rails db:prepare"

# Start background jobs in the background
log "Starting background jobs..."
su rails -c "cd /rails && bundle exec bin/jobs" &

# Test nginx configuration
log "Testing nginx configuration..."
nginx -t

# Start nginx with passenger in the foreground
log "Starting nginx with Passenger..."
exec nginx -g "daemon off;"

# If we get here, one of the processes exited
cleanup
