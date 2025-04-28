# frozen_string_literal: true

# Runs Solid Queue dispatcher, worker, and scheduler in-process to avoid SQLite contention.
# See: https://github.com/basecamp/solid_queue/issues/xxx for rationale.
if Rails.env.development? || Rails.env.production?
    Rails.application.config.after_initialize do
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

      at_exit do
        Rails.logger.info "Shutting down Solid Queue components..."
        dispatcher&.stop
        worker&.stop
        scheduler&.stop
        [ dispatcher_thread, worker_thread, scheduler_thread ].each do |thread|
          thread&.join(5)
        end
      end
    end
end
