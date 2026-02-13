# typed: strict
# frozen_string_literal: true
# shareable_constant_value: literal

# Sidekiq configuration with DragonflyDB backend

require "sidekiq"
require "sidekiq-cron"

redis_url = ENV.fetch("REDIS_URL") { "redis://127.0.0.1:6379/0" }

# Configure Sidekiq client (for enqueuing jobs from web processes)
Sidekiq.configure_client do |config|
  config.redis = {
    url: redis_url,
    driver: :hiredis,
    network_timeout: 5,
    pool_timeout: 5
  }
end

# Configure Sidekiq server (for processing jobs)
Sidekiq.configure_server do |config|
  config.redis = {
    url: redis_url,
    driver: :hiredis,
    network_timeout: 5,
    pool_timeout: 5
  }
  # Error handling with Sentry
  config.error_handlers << proc do |ex, ctx_hash|
    if defined?(Sentry)
      Sentry.with_scope do |scope|
        scope.set_context("sidekiq", ctx_hash)
        Sentry.capture_exception(ex)
      end
    end
  end

  # Death handler for permanently failed jobs
  config.death_handlers << proc do |job, ex|
    Rails.logger.error "[Sidekiq] Job #{job['class']} permanently failed: #{ex.message}"
    if defined?(Sentry)
      Sentry.capture_message(
        "Sidekiq job permanently failed",
        level: :error,
        extra: { job_class: job["class"], job_id: job["jid"], error: ex.message }
      )
    end
  end

  # Load scheduled/cron jobs from recurring.yml
  schedule_file = Rails.root.join("config/sidekiq_schedule.yml")
  if File.exist?(schedule_file)
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
    Sidekiq.logger.info "[Sidekiq] Loaded cron schedule from #{schedule_file}"
  end
end

# Global Sidekiq configuration
Sidekiq.default_job_options = {
  "backtrace" => true,
  "retry" => 5
}

require "sidekiq/worker_killer"

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::WorkerKiller, max_rss: 2048, grace_time: 0
  end
end

Sidekiq.transactional_push!
