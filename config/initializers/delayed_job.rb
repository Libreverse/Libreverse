# frozen_string_literal: true
# shareable_constant_value: literal

require "delayed_job_recurring"
require "worker_killer/delayed_job_plugin"

Rails.application.config.after_initialize do
  # Only set up recurring jobs if the delayed_jobs table exists
  begin
    next unless ActiveRecord::Base.connection.table_exists?("delayed_jobs")
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
    next
  end

  # ----- Recurring Jobs -----
  # Cleanup abandoned guests daily at 3:00am
  # Delayed::Job.where(name: 'cleanup_abandoned_guests').destroy_all
  # Delayed::Job.create!(
  #   name: 'cleanup_abandoned_guests',
  #   klass: 'CleanupAbandonedGuestsJob',
  #   cron: '0 3 * * *'
  # )

  # Retention tasks daily at 3:00am
  # Delayed::Job.where(name: 'retention_tasks').destroy_all
  # Delayed::Job.create!(
  #   name: 'retention_tasks',
  #   klass: 'RetentionTasksJob',
  #   cron: '0 3 * * *'
  # )

  # Metaverse indexing every 12 hours
  # Delayed::Job.where(name: 'metaverse_indexing').destroy_all
  # Delayed::Job.create!(
  #   name: 'metaverse_indexing',
  #   method_name: :perform_later,
  #   klass: 'ScheduledIndexingJob',
  #   run_at: Time.now,
  #   cron: '0 */12 * * *'
  # )

=begin
  # ----- WorkerKiller: OOMLimiter with spaced memory limits (512MB-600MB) -----
  Delayed::Worker.plugins.tap do |plugins|
    delayed_job_killer = WorkerKiller::Killer::DelayedJob.new

    # Set min and max to different values to randomize kill threshold (e.g., between 512MB and 600MB)
    plugins << WorkerKiller::DelayedJobPlugin::OOMLimiter.new(
      killer: delayed_job_killer,
      min: 419_430_400,
      max: 524_288_000
    )
  end
=end
end
