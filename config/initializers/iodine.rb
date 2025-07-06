# config/iodine.rb (or equivalent)
# frozen_string_literal: true

require "English"
require "etc"

# Detect CPU cores (modified to prioritize physical cores)
def hardware_cores
  case RUBY_PLATFORM
  when /linux/
    output = `lscpu`
    if $CHILD_STATUS.success?
      output.lines.each do |line|
        # Prioritize physical cores over logical (hyper-threading)
        return Regexp.last_match(1).to_i if line =~ /^Core\(s\) per socket:\s+(\d+)/
      end
    end
    return File.read("/proc/cpuinfo").scan(/^processor\s*:/).count / 2 if File.exist?("/proc/cpuinfo") # Approximate physical cores
  when /darwin/
    output = `sysctl -n hw.physicalcpu` # Physical cores
    return output.strip.to_i if $CHILD_STATUS.success?
  when /win32|mingw|cygwin/
    output = `wmic cpu get NumberOfCores` # Physical cores
    if $CHILD_STATUS.success?
      output.lines.each do |line|
        return line.strip.to_i if /^\d+/.match?(line)
      end
    end
  end

  # Fallback to Etc.nprocessors (may include hyper-threading)
  cores = Etc.nprocessors
  cores = cores / 2 if cores > 1 # Estimate physical cores if hyper-threading is likely
  return cores if cores.positive?

  # Final fallback
  1
end

if defined?(Iodine)
  # Calculate workers and threads based on CPU cores
  cpu_cores = hardware_cores

  # I/O-bound workload: workers = cores * 2
  iodine_workers = cpu_cores * 2

  # Threads: Start with (cores * 2) - 4, but ensure a minimum of 5 and cap at 20
  iodine_threads = [(cpu_cores * 2) - 4, 5].max
  iodine_threads = [iodine_threads, 20].min # Cap at 20 for I/O-bound practicality

  # Apply settings only if not already set
  current_threads = Iodine.threads.to_i
  Iodine.threads = iodine_threads if current_threads.zero?
  Iodine.workers = iodine_workers if Iodine.workers.zero?

  # Port configuration
  Iodine::DEFAULT_SETTINGS[:port] = "3000"

  # Reverse proxy detection
  def behind_reverse_proxy?
    heroku_detected = ENV.key?("DYNO")
    railway_detected = ENV.key?("RAILWAY_ENVIRONMENT")
    render_detected = ENV.key?("RENDER")
    fly_detected = ENV.key?("FLY_APP_NAME")
    heroku_detected || railway_detected || render_detected || fly_detected
  end

  # Static file serving
  if Rails.env.production?
    enable_static = !behind_reverse_proxy?
    if enable_static
      Iodine::DEFAULT_SETTINGS[:public] = Rails.public_path.to_s
      Rails.logger.info "Iodine: Static file serving enabled (no reverse proxy detected)"
    else
      Rails.logger.info "Iodine: Static file serving disabled (reverse proxy detected)"
    end
  elsif Rails.env.development?
    Iodine::DEFAULT_SETTINGS[:public] ||= Rails.public_path.to_s
  end

  # Memory optimization (hot restart)
  if Rails.env.production?
    Iodine.run_every(4 * 60 * 60 * 1000) do
      if Iodine.master?
        Rails.logger.info "Iodine: Performing hot restart for memory optimization"
        Process.kill("SIGUSR1", Process.pid)
      end
    end
  end

  # Connection and timeout optimizations
  Iodine::DEFAULT_SETTINGS[:timeout] ||= 40

  # WebSocket optimizations
  if Rails.application.config.respond_to?(:action_cable)
    Iodine::DEFAULT_SETTINGS[:max_headers] ||= 64
  end

  # Security and resource limits
  Iodine::DEFAULT_SETTINGS[:max_body] ||= 2048 # MB (2GB)

  # Configuration summary
  static_files_status = if Rails.env.production?
    behind_reverse_proxy? ? "disabled (proxy auto-detected)" : "enabled (no proxy detected)"
  else
    "enabled (development)"
  end

  Rails.logger.info "Iodine Configuration - Workers: #{Iodine.workers}, Threads: #{Iodine.threads}, CPU Cores: #{cpu_cores}, Static Files: #{static_files_status}"

  # Set environment variables for database pool
  ENV['RAILS_MAX_THREADS'] = iodine_threads.to_s
  ENV['WEB_CONCURRENCY'] = iodine_workers.to_s
end