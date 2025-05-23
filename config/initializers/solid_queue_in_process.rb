# frozen_string_literal: true

# Runs Solid Queue dispatcher, worker, and scheduler in-process to avoid SQLite contention.
# See: https://github.com/basecamp/solid_queue/issues/xxx for rationale.
if Rails.env.development? || Rails.env.production?
    Rails.application.config.after_initialize do
      # Guard clauses – only start the embedded Solid Queue runners when
      # 1. We are running inside a long-lived web/server process (eg. Puma),
      # 2. The database is reachable **and** the Solid Queue tables exist.
      next if defined?(Rails::Console) || File.basename($PROGRAM_NAME) == "rake" || ENV["SKIP_EMBEDDED_SOLID_QUEUE"].present?

      require "concurrent"

      # Thread-safe flag to ensure bootstrapping runs only once
      @bootstrap_started ||= Concurrent::AtomicBoolean.new(false)

      # Atomically check and set - exit early if bootstrap was already started
      next if @bootstrap_started.make_true

      # Delay startup until Solid Queue tables are present
      dispatcher = worker = scheduler = nil
      dispatcher_thread = worker_thread = scheduler_thread = nil

      bootstrap_thread = Thread.new do
        Thread.current.name = "solid_queue_bootstrap"

        loop do
          begin
            ActiveRecord::Base.connection_pool.with_connection do |conn|
              if conn.data_source_exists?("solid_queue_jobs")
                Rails.logger.info "Solid Queue tables detected. Bootstrapping dispatcher/worker/scheduler..."
                break
              else
                Rails.logger.info "Solid Queue tables not yet found; retrying in 5s..."
              end
            end
          rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid, ActiveRecord::ConnectionTimeoutError => e
            Rails.logger.info "Database not ready (#{e.class}); retrying in 5s..."
          end

          sleep 5
        end

        # Dispatcher
        dispatcher = SolidQueue::Dispatcher.new(
          polling_interval: 5,
          batch_size: Rails.env.production? ? 200 : 500,
          concurrency_maintenance_interval: 600
        )
        dispatcher_thread = Thread.new do
          Thread.current.name = "solid_queue_dispatcher"
          Rails.logger.info "Starting Solid Queue dispatcher in-process"
          begin
            dispatcher.start
          rescue StandardError => e
            Rails.logger.error "Solid Queue Dispatcher Error: #{e.message}"
            Rails.logger.error e.backtrace.join("\n")
            sleep 5
            retry
          end
        end

        # Worker
        worker = SolidQueue::Worker.new(
          queues: [ "*" ],
          threads: 1, # Single thread to avoid concurrency issues
          polling_interval: 2
        )
        worker_thread = Thread.new do
          Thread.current.name = "solid_queue_worker"
          Rails.logger.info "Starting Solid Queue worker in-process"
          begin
            worker.start
          rescue StandardError => e
            Rails.logger.error "Solid Queue Worker Error: #{e.message}"
            Rails.logger.error e.backtrace.join("\n")
            sleep 5
            retry
          end
        end

        # Scheduler
        scheduler = SolidQueue::Scheduler.new(
          polling_interval: 10,
          recurring_tasks: [] # or your recurring tasks array
        )
        scheduler_thread = Thread.new do
          Thread.current.name = "solid_queue_scheduler"
          Rails.logger.info "Starting Solid Queue scheduler in-process"
          begin
            scheduler.start
          rescue StandardError => e
            Rails.logger.error "Solid Queue Scheduler Error: #{e.message}"
            Rails.logger.error e.backtrace.join("\n")
            sleep 5
            retry
          end
        end
      end

      at_exit do
        Rails.logger.info "Shutting down Solid Queue components..."
        dispatcher&.stop
        worker&.stop
        scheduler&.stop
        [ bootstrap_thread, dispatcher_thread, worker_thread, scheduler_thread ].each do |thread|
          thread&.join(5)
        end
      end
    end
end
