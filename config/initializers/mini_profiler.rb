# frozen_string_literal: true

if Rails.env.development?
  require 'rack-mini-profiler'

  Rack::MiniProfiler.config.position = 'right'
  Rack::MiniProfiler.config.start_hidden = true
  Rack::MiniProfiler.config.skip_paths ||= []
  Rack::MiniProfiler.config.skip_paths += [
    /assets\//,
    /images\//,
    /favicon\.ico$/,
    /packs\//
  ]

  # Persistent storage in Redis when available, else memory
  begin
    require 'redis'
    url = ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379/0')
    Rack::MiniProfiler.config.storage = Rack::MiniProfiler::RedisStore
    Rack::MiniProfiler.config.storage_options = { url: url }
  rescue LoadError
    Rack::MiniProfiler.config.storage = Rack::MiniProfiler::MemoryStore
  end

  # Insert middleware early for accurate timings
  Rails.application.config.middleware.insert_before 0, Rack::MiniProfiler
end
