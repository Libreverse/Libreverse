# frozen_string_literal: true
# shareable_constant_value: literal

# Puma configuration for Libreverse Rails application
# This file configures the Puma webserver for deployment

# Application-specific configuration
hostname = ENV.fetch("HOSTNAME", "0.0.0.0")
port = ENV.fetch("PORT", 3002).to_i
ENV.fetch("RAILS_ENV", "production")

# Performance tuning
workers ENV.fetch("WEB_CONCURRENCY", 2).to_i # Reduced for development
threads_min = ENV.fetch("PUMA_MIN_THREADS", 1).to_i
threads_max = ENV.fetch("PUMA_MAX_THREADS", 5).to_i
threads threads_min, threads_max

# Worker timeout
worker_timeout ENV.fetch("TIMEOUT", 60).to_i

# Preload app for faster worker boots
preload_app!

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

# Logging
# stdout_redirect stdout: "/dev/stdout", stderr: "/dev/stderr", append: true

# Set master PID and state locations
pidfile ENV.fetch("PIDFILE", "tmp/pids/server.pid")
state_path ENV.fetch("STATEFILE", "tmp/pids/puma.state")
