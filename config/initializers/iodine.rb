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

  # Auto-determined thread configuration based on CPU cores and workload
  # For CPU-bound work: cores - 1, for I/O-bound work: cores * 2
  # Rails apps are typically I/O-bound (database, API calls, etc.)
  # Subtract 4 threads: 3 for Solid Queue + 1 for gRPC server running in same process
  iodine_threads = (cpu_cores * 2) - 4

  # Worker process configuration - locked to single worker
  iodine_workers = 1 # Always use single worker regardless of environment or CPU cores

  # Apply optimized settings only if not already set
  current_threads = Iodine.threads.to_i
Iodine.threads = iodine_threads if current_threads.zero?
  Iodine.workers = iodine_workers if Iodine.workers.zero?

  # Port configuration - always use port 3000
  Iodine::DEFAULT_SETTINGS[:port] = "3000"

  # Advanced Performance Optimizations

  # Detect if we're behind a reverse proxy to avoid double-serving static files
  def behind_reverse_proxy?
    # NOTE: HTTP proxy headers (X-Forwarded-For, X-Real-IP, etc.) are only available
    # in request.env during HTTP requests, not in ENV at boot time. For header-based
    # detection, implement a Rack middleware that checks request.env per request.

    # Platform checks - these platforms typically use reverse proxies by default
    heroku_detected = ENV.key?("DYNO") # Heroku always uses a router/proxy
    railway_detected = ENV.key?("RAILWAY_ENVIRONMENT") # Railway uses reverse proxy
    render_detected = ENV.key?("RENDER") # Render uses reverse proxy
    fly_detected = ENV.key?("FLY_APP_NAME") # Fly.io uses reverse proxy

    heroku_detected || railway_detected || render_detected || fly_detected
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
    # Hot restart configuration for memory management
    # Restart workers every 4 hours to prevent memory bloat
    Iodine.run_every(4 * 60 * 60 * 1000) do
      if Iodine.master?
        Rails.logger.info "Iodine: Performing hot restart for memory optimization"
        Process.kill("SIGUSR1", Process.pid)
      end
    end
  end

  # Connection and timeout optimizations
  Iodine::DEFAULT_SETTINGS[:timeout] ||= 40

  # WebSocket and upgrade optimizations (if using WebSockets)
  if Rails.application.config.respond_to?(:action_cable)
    # Optimize for WebSocket connections
    Iodine::DEFAULT_SETTINGS[:max_headers] ||= 64 # Reduce header limit for WS
  end

  # Security and resource limits
  Iodine::DEFAULT_SETTINGS[:max_body] ||= 2048 # MB (2GB)

  # Configuration summary for debugging
  static_files_status = if Rails.env.production?
    proxy_detected = behind_reverse_proxy?
    proxy_detected ? "disabled (proxy auto-detected)" : "enabled (no proxy detected)"
  else
    "enabled (development)"
  end

  Rails.logger.info "Iodine Configuration - Workers: #{Iodine.workers}, Threads: #{Iodine.threads}, CPU Cores: #{cpu_cores}, Static Files: #{static_files_status}"
end
