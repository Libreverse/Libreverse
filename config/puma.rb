# frozen_string_literal: true

require "etc"

# Detect available virtual CPU cores. Used to auto‑tune thread and worker counts
# when explicit ENV overrides are not provided.

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches Active Record's default thread pool size.
#
# Configure maximum threads available for Puma, defaulting to 5.
threads 1, 1

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
port Integer(ENV.fetch("PORT") { 3000 })

# Specifies the `environment` that Puma will run in.
environment(ENV.fetch("RAILS_ENV") { "development" })

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
workers 1

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
preload_app!

# Run Solid Queue supervisor alongside Puma so background jobs share the same
# process pool.
plugin :solid_queue
# Allow `bin/rails restart` to restart Puma.
plugin :tmp_restart
