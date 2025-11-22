# frozen_string_literal: true
# shareable_constant_value: literal

require "delayed_job_recurring"
require "worker_killer/delayed_job_plugin"

Rails.application.config.after_initialize do
  # Only set up recurring jobs if the delayed_jobs table exists and has required columns
  begin
    next unless ActiveRecord::Base.connection.table_exists?("delayed_jobs")
    next unless ActiveRecord::Base.connection.column_exists?("delayed_jobs", "klass")
    next unless Delayed::Job.attribute_names.include?("klass")
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
    next
  end

  # ----- Recurring Jobs -----
  # Cleanup abandoned guests daily at 3:00am
  begin
    Delayed::Job.where(name: 'cleanup_abandoned_guests').destroy_all
    Delayed::Job.create!(
      name: 'cleanup_abandoned_guests',
      klass: 'CleanupAbandonedGuestsJob',
      cron: '0 3 * * *'
    )
  rescue ActiveModel::UnknownAttributeError
    # Skip if klass attribute not available
  end

  # Retention tasks daily at 3:00am
  begin
    # Delayed::Job.where(name: 'retention_tasks').destroy_all
    Delayed::Job.create!(
      name: 'retention_tasks',
      klass: 'RetentionTasksJob',
      cron: '0 3 * * *'
    )
  rescue ActiveModel::UnknownAttributeError
    # Skip if klass attribute not available
  end

  # Metaverse indexing every 12 hours
  begin
    Delayed::Job.where(name: 'metaverse_indexing').destroy_all
    Delayed::Job.create!(
      name: 'metaverse_indexing',
      method_name: :perform_later,
      klass: 'ScheduledIndexingJob',
      run_at: Time.now,
      cron: '0 */12 * * *'
    )
  rescue ActiveModel::UnknownAttributeError
    # Skip if klass attribute not available
  end

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
end
