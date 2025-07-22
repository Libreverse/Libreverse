# frozen_string_literal: true

# Spawns Solid Queue as a separate process to avoid SQLite contention.
require "English"
Rails.logger.info "Solid Queue initializer loading (Rails.env: #{Rails.env})"

unless Rails.env.test?
  Rails.logger.info "Solid Queue environment check passed, setting up after_initialize"
  Rails.application.config.after_initialize do
    Rails.logger.info "Solid Queue after_initialize callback triggered"
    Rails.logger.info "PROGRAM_NAME: #{$PROGRAM_NAME}, Rails::Console defined?: #{defined?(Rails::Console)}"

    # Guard clauses – only start Solid Queue when running the web server
    # and ensure we only start once (not in every forked worker)
    Rails.logger.info "Solid Queue guard clause check: Console? #{defined?(Rails::Console)}, PROGRAM_NAME: #{File.basename($PROGRAM_NAME)}"
    next if Rails.const_defined?(:Console) ||
            %w[rake runner].include?(File.basename($PROGRAM_NAME))

    # Additional check for worker processes - skip if we're likely in a forked worker
    # Most servers set environment variables or have other indicators for worker processes
    if Process.pid != $PROCESS_ID
      Rails.logger.info "Skipping Solid Queue startup - appears to be in worker process"
      next
    end

    Rails.logger.info "Solid Queue guard clauses passed, spawning separate process..."

    require "concurrent"

    # Use a global variable for the flag to ensure it's unique across the entire process
    # Also check if another process already started Solid Queue by checking for running processes
    $solid_queue_process_started ||= Concurrent::AtomicBoolean.new(false)

    # Atomically check and set - exit early if process was already started
    if $solid_queue_process_started.true?
      Rails.logger.info "Solid Queue already started in this process, skipping"
      next
    end

    # Check if Solid Queue is already running by looking for existing processes
    begin
      existing_pids = `pgrep -f "solid_queue:start"`.strip.split("\n").map(&:to_i)
      if existing_pids.any?
        Rails.logger.info "Solid Queue already running (PIDs: #{existing_pids.join(', ')}), skipping startup"
        next
      end
    rescue StandardError => e
      Rails.logger.warn "Could not check for existing Solid Queue processes: #{e.message}"
    end

    $solid_queue_process_started.make_true

    # Spawn Solid Queue as a separate process
    begin
      solid_queue_pid = Process.spawn(
        { "RAILS_ENV" => Rails.env.to_s },
        "bundle", "exec", "rake", "solid_queue:start",
        chdir: Rails.root.to_s,
        out: :err # Redirect stdout to stderr so logs appear in the same stream
      )

      Rails.logger.info "Solid Queue process started with PID: #{solid_queue_pid}"

      # Store PID for cleanup
      $solid_queue_pid = solid_queue_pid

      # Set up cleanup on exit
      at_exit do
        if $solid_queue_pid
          Rails.logger.info "Shutting down Solid Queue process (PID: #{$solid_queue_pid})..."
          begin
            Process.kill("TERM", $solid_queue_pid)
            # Give it time to shutdown gracefully
            Timeout.timeout(10) do
              Process.wait($solid_queue_pid)
            end
            Rails.logger.info "Solid Queue process shutdown complete"
          rescue Errno::ESRCH
            # Process already dead
            Rails.logger.info "Solid Queue process already terminated"
          rescue Timeout::Error
            Rails.logger.warn "Solid Queue process didn't shutdown gracefully, forcing kill"
            begin
              Process.kill("KILL", $solid_queue_pid)
            rescue StandardError
              nil
            end
          rescue StandardError => e
            Rails.logger.error "Error shutting down Solid Queue process: #{e.message}"
          end
        end
      end

      # Detach the process so we don't wait for it
      Process.detach(solid_queue_pid)
    rescue StandardError => e
      Rails.logger.error "Failed to start Solid Queue process: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end
end
