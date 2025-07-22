# frozen_string_literal: true

# Spawns Litestream as a separate process for database replication.
# Similar to the solid_queue_in_process initializer but for Litestream.
require "English"
Rails.logger.info "Litestream initializer loading (Rails.env: #{Rails.env})"

unless Rails.env.test?
  Rails.logger.info "Litestream environment check passed, setting up after_initialize"
  Rails.application.config.after_initialize do
    Rails.logger.info "Litestream after_initialize callback triggered"
    Rails.logger.info "PROGRAM_NAME: #{$PROGRAM_NAME}, Rails::Console defined?: #{defined?(Rails::Console)}"

    # Guard clauses – only start Litestream when running the web server
    # and ensure we only start once (not in every forked worker)
    Rails.logger.info "Litestream guard clause check: Console? #{defined?(Rails::Console)}, PROGRAM_NAME: #{File.basename($PROGRAM_NAME)}"
    next if Rails.const_defined?(:Console) ||
            %w[rake runner].include?(File.basename($PROGRAM_NAME))

    # Additional check for worker processes - skip if we're likely in a forked worker
    # Most servers set environment variables or have other indicators for worker processes
    $PROCESS_ID ||= Process.pid
    if Process.pid != $PROCESS_ID
      Rails.logger.info "Skipping Litestream startup - appears to be in worker process"
      next
    end

    # Check if Litestream environment variables are available
    required_env_vars = %w[LITESTREAM_REPLICA_BUCKET LITESTREAM_ACCESS_KEY_ID LITESTREAM_SECRET_ACCESS_KEY]
    missing_vars = required_env_vars.select { |var| ENV[var].blank? }

    if missing_vars.any?
      if Rails.env.production?
        Rails.logger.fatal "CRITICAL: Litestream is required for production durability but missing environment variables: #{missing_vars.join(', ')}"
        raise "Production deployment failed: Litestream requires the following environment variables for database durability: #{missing_vars.join(', ')}"
      else
        Rails.logger.info "Litestream startup skipped - missing environment variables: #{missing_vars.join(', ')}"
        next
      end
    end

    Rails.logger.info "Litestream guard clauses passed, spawning separate process..."

    require "concurrent"

    # Use a global variable for the flag to ensure it's unique across the entire process
    # Also check if another process already started Litestream by checking for running processes
    $litestream_process_started ||= Concurrent::AtomicBoolean.new(false)

    # Atomically check and set - exit early if process was already started
    if $litestream_process_started.true?
      Rails.logger.info "Litestream already started in this process, skipping"
      next
    end

    # Check if Litestream is already running by looking for existing processes
    begin
      existing_pids = `pgrep -f "litestream:replicate"`.strip.split("\n").map(&:to_i)
      if existing_pids.any?
        Rails.logger.info "Litestream already running (PIDs: #{existing_pids.join(', ')}), skipping startup"
        next
      end
    rescue StandardError => e
      Rails.logger.warn "Could not check for existing Litestream processes: #{e.message}"
    end

    $litestream_process_started.make_true

    # Spawn Litestream as a separate process
    begin
      litestream_pid = Process.spawn(
        {
          "RAILS_ENV" => Rails.env.to_s,
          "LITESTREAM_REPLICA_BUCKET" => ENV["LITESTREAM_REPLICA_BUCKET"],
          "LITESTREAM_ACCESS_KEY_ID" => ENV["LITESTREAM_ACCESS_KEY_ID"],
          "LITESTREAM_SECRET_ACCESS_KEY" => ENV["LITESTREAM_SECRET_ACCESS_KEY"],
          "LITESTREAM_REPLICA_REGION" => ENV.fetch("LITESTREAM_REPLICA_REGION") { "us-east-1" },
          "LITESTREAM_REPLICA_ENDPOINT" => ENV["LITESTREAM_REPLICA_ENDPOINT"]
        }.compact,
        "bundle", "exec", "rails", "litestream:replicate",
        chdir: Rails.root.to_s,
        out: :err # Redirect stdout to stderr so logs appear in the same stream
      )

      Rails.logger.info "Litestream process started with PID: #{litestream_pid}"

      # Store PID for cleanup
      $litestream_pid = litestream_pid

      # Set up cleanup on exit
      at_exit do
        if $litestream_pid
          Rails.logger.info "Shutting down Litestream process (PID: #{$litestream_pid})..."
          begin
            Process.kill("TERM", $litestream_pid)
            # Give it time to shutdown gracefully
            Timeout.timeout(10) do
              Process.wait($litestream_pid)
            end
            Rails.logger.info "Litestream process shutdown complete"
          rescue Errno::ESRCH
            # Process already dead
            Rails.logger.info "Litestream process already terminated"
          rescue Timeout::Error
            Rails.logger.warn "Litestream process didn't shutdown gracefully, forcing kill"
            begin
              Process.kill("KILL", $litestream_pid)
            rescue StandardError
              nil
            end
          rescue StandardError => e
            Rails.logger.error "Error shutting down Litestream process: #{e.message}"
          end
        end
      end

      # Detach the process so we don't wait for it
      Process.detach(litestream_pid)
    rescue StandardError => e
      Rails.logger.error "Failed to start Litestream process: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end
end
