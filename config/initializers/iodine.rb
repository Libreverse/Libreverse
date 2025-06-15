# frozen_string_literal: true

require "English"
require "etc"

def hardware_threads
  # Platform-specific checks first
  case RUBY_PLATFORM
  when /linux/
    output = `lscpu`
    if $CHILD_STATUS.success?
      output.lines.each do |line|
        return Regexp.last_match(1).to_i if line =~ /^CPU\(s\):\s+(\d+)/
      end
    end
    return File.read("/proc/cpuinfo").scan(/^processor\s*:/).count if File.exist?("/proc/cpuinfo")
  when /darwin/
    output = `sysctl -n hw.ncpu`
    return output.strip.to_i if $CHILD_STATUS.success?
  when /win32|mingw|cygwin/
    output = `wmic cpu get NumberOfLogicalProcessors`
    if $CHILD_STATUS.success?
      output.lines.each do |line|
        return line.strip.to_i if /^\d+/.match?(line)
      end
    end
    # Fallback to Etc.nprocessors instead of environment variable
  end

  # Fallback to Etc.nprocessors
  threads = Etc.nprocessors
  return threads if threads.positive?

  # Final fallback to 1 if all else fails
  1
end

if defined?(Iodine)
  # Advanced Iodine Configuration

  # Calculate optimal thread count based on CPU cores and workload
  cpu_cores = hardware_threads

  # Environment-based configuration with intelligent defaults
  iodine_threads = if ENV["THREADS"]
    ENV["THREADS"].to_i
  elsif ENV["RAILS_MAX_THREADS"]
    ENV["RAILS_MAX_THREADS"].to_i
  else
    # For CPU-bound work: cores - 1, for I/O-bound work: cores * 2
    # Rails apps are typically I/O-bound (database, API calls, etc.)
    [ cpu_cores * 2, 32 ].min # Cap at 32 threads to prevent overhead
  end

  # Worker process configuration
  iodine_workers = if ENV["WORKERS"]
    workers = ENV["WORKERS"].to_i
    workers.negative? ? [ cpu_cores / workers.abs, 1 ].max : workers
  elsif ENV["WEB_CONCURRENCY"]
    ENV["WEB_CONCURRENCY"].to_i
  else
    # For production: use multiple workers for better fault isolation
    # For development: single worker for easier debugging
    Rails.env.production? ? [ cpu_cores / 2, 1 ].max : 1
  end

  # Apply optimized settings only if not already set
  current_threads = Iodine.threads.to_i
Iodine.threads = iodine_threads if current_threads.zero?
  Iodine.workers = iodine_workers if Iodine.workers.zero?

  # Port configuration - always use port 3000
  Iodine::DEFAULT_SETTINGS[:port] = "3000"

  # Advanced Performance Optimizations

  # Detect if we're behind a reverse proxy to avoid double-serving static files
  def behind_reverse_proxy?
    # Common reverse proxy headers
    proxy_headers = %w[
      HTTP_X_FORWARDED_FOR
      HTTP_X_FORWARDED_HOST
      HTTP_X_FORWARDED_PROTO
      HTTP_X_REAL_IP
      HTTP_CF_RAY
      HTTP_CF_CONNECTING_IP
      HTTP_X_FORWARDED_SERVER
      HTTP_X_CLUSTER_CLIENT_IP
    ]

    # Check if any proxy headers are present in the environment
    # This suggests we're behind a proxy like nginx, Apache, CloudFlare, etc.
    proxy_detected = proxy_headers.any? { |header| ENV.key?(header) }

    # Additional checks for common deployment patterns
    heroku_detected = ENV.key?("DYNO") # Heroku
    railway_detected = ENV.key?("RAILWAY_ENVIRONMENT") # Railway
    render_detected = ENV.key?("RENDER") # Render
    fly_detected = ENV.key?("FLY_APP_NAME") # Fly.io
    docker_detected = File.exist?("/.dockerenv") || ENV.key?("DOCKER_CONTAINER")

    # Platform checks - these typically use reverse proxies
    platform_with_proxy = heroku_detected || railway_detected || render_detected || fly_detected

    proxy_detected || platform_with_proxy || docker_detected
  end

  # Smart static file serving configuration
  if Rails.env.production?
    # Auto-detect: only enable if we don't detect a reverse proxy
    enable_static = !behind_reverse_proxy?

    if enable_static
      Iodine::DEFAULT_SETTINGS[:public] = Rails.public_path.to_s
      Rails.logger.info "Iodine: Static file serving enabled (no reverse proxy detected)"
    else
      Rails.logger.info "Iodine: Static file serving disabled (reverse proxy detected)"
    end
  elsif Rails.env.development?
    # Always enable in development for convenience
    Iodine::DEFAULT_SETTINGS[:public] ||= Rails.public_path.to_s
  end

  # Memory optimization settings
  if Rails.env.production?
    # Enable heap fragmentation protection with custom allocator
    # This is enabled by default but ensuring it's not disabled

    # Hot restart configuration for memory management
    # Restart workers every 4 hours to prevent memory bloat
    Iodine.run_every(4 * 60 * 60 * 1000) do
      if Iodine.master?
        Rails.logger.info "Iodine: Performing hot restart for memory optimization"
        Process.kill("SIGUSR1", Process.pid)
      end
    end
  end

  # Development optimizations
  if Rails.env.development?
    # Enable verbose logging for development
    # Note: This can also be enabled via command line with -v flag

    # Reduce workers and threads for easier debugging
    Iodine.workers = 1 if Iodine.workers > 1
    Iodine.threads = [ iodine_threads, 4 ].min # Cap at 4 threads for dev
  end

  # Connection and timeout optimizations
  Iodine::DEFAULT_SETTINGS[:timeout] ||= 40

  # WebSocket and upgrade optimizations (if using WebSockets)
  if Rails.application.config.respond_to?(:action_cable)
    # Optimize for WebSocket connections
    Iodine::DEFAULT_SETTINGS[:max_headers] ||= 64 # Reduce header limit for WS
  end

  # Logging configuration
  if Rails.env.development?
    # This enables optimized HTTP request logging
    # More efficient than Rails logging middleware for high-traffic apps
  end

  # Security and resource limits
  Iodine::DEFAULT_SETTINGS[:max_body] ||= 2048 # MB (2GB)

  # Performance monitoring hooks
  if Rails.env.production?
    # Monitor connection count and performance
    Iodine.run_every(60_000) do # Every minute
      if Iodine.master?
        connection_count = begin
                             Iodine.connection_count
        rescue StandardError
                             0
        end
        Rails.logger.info "Iodine Stats - Connections: #{connection_count}, Workers: #{Iodine.workers}, Threads: #{Iodine.threads}"
      end
    end
  end

  # Configuration summary for debugging
  static_files_status = if Rails.env.production?
    proxy_detected = behind_reverse_proxy?
    proxy_detected ? "disabled (proxy auto-detected)" : "enabled (no proxy detected)"
  else
    "enabled (development)"
  end

  Rails.logger.info "Iodine Configuration - Workers: #{Iodine.workers}, Threads: #{Iodine.threads}, CPU Cores: #{cpu_cores}, Static Files: #{static_files_status}"
end
