# frozen_string_literal: true
# shareable_constant_value: literal

# Centralized Redis/DragonflyDB configuration
# DragonflyDB is a Redis-compatible in-memory database

REDIS_URL = ENV.fetch("REDIS_URL") { "redis://127.0.0.1:6379/0" }

# Configure Redis connection settings
# Note: TruffleRuby only supports the :ruby driver, not :hiredis
REDIS_CONFIG = {
  url: REDIS_URL,
  connect_timeout: 5,
  read_timeout: 1,
  write_timeout: 1,
  reconnect_attempts: 3
}.freeze

# Shared Redis connection pool for general use
# Using ConnectionPool for thread-safety
require "connection_pool"

REDIS_POOL = ConnectionPool.new(size: ENV.fetch("RAILS_MAX_THREADS", 5).to_i, timeout: 5) do
  Redis.new(REDIS_CONFIG)
end

# Helper method to get a Redis connection from the pool
def redis
  REDIS_POOL.with { |conn| yield conn }
end

Rails.logger.info "[Redis] Configured with DragonflyDB at #{REDIS_URL}"
