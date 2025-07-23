# frozen_string_literal: true

# Background job for running all enabled indexers on a schedule
class ScheduledIndexingJob < ApplicationJob
  queue_as :default

  # Don't retry this job automatically - let the scheduler handle it
  # retry_on StandardError, wait: 1.hour, attempts: 2

  def perform(force_run: false)
    Rails.logger.info "Starting ScheduledIndexingJob"

    # Load indexer configuration
    config = load_indexer_config
    return unless config

    enabled_indexers = find_enabled_indexers(config)

    if enabled_indexers.empty?
      Rails.logger.info "No enabled indexers found"
      return
    end

    Rails.logger.info "Found #{enabled_indexers.size} enabled indexers: #{enabled_indexers.keys.join(', ')}"

    # Queue individual indexer jobs
    enabled_indexers.each do |platform_name, indexer_config|
        indexer_class_name = indexer_class_name_for_platform(platform_name)

        # Check if indexer class exists
        indexer_class = indexer_class_name.constantize

        # Skip if recently run (unless forced)
        unless force_run || should_run_indexer?(indexer_class, indexer_config)
          Rails.logger.info "Skipping #{platform_name} - recently run or not scheduled"
          next
        end

        Rails.logger.info "Queueing indexer job for #{platform_name}"
        IndexerJob.perform_later(indexer_class_name, indexer_config)
    rescue NameError => e
        Rails.logger.warn "Indexer class not found for #{platform_name}: #{e.message}"
    rescue StandardError => e
        Rails.logger.error "Failed to queue indexer for #{platform_name}: #{e.message}"
    end

    Rails.logger.info "Completed ScheduledIndexingJob"
  end

  private

  def load_indexer_config
    config_path = Rails.root.join("config/indexers.yml")
    return nil unless File.exist?(config_path)

    YAML.load_file(config_path)
  rescue StandardError => e
    Rails.logger.error "Failed to load indexer config: #{e.message}"
    nil
  end

  def find_enabled_indexers(config)
    base_indexers = config["indexers"] || {}
    env_overrides = config[Rails.env] || {}
    env_indexers = env_overrides["indexers"] || {}

    enabled = {}

    base_indexers.each do |platform_name, base_config|
      # Apply environment-specific overrides
      env_config = env_indexers[platform_name] || {}
      merged_config = base_config.deep_merge(env_config)

      # Check if enabled
      enabled[platform_name] = merged_config if merged_config["enabled"] == true
    end

    enabled
  end

  def indexer_class_name_for_platform(platform_name)
    # Convert platform name to class name
    # e.g., 'decentraland' -> 'Metaverse::DecentralandIndexer'
    class_name = "#{platform_name.camelize}Indexer"
    "Metaverse::#{class_name}"
  end

  def should_run_indexer?(indexer_class, config)
    # Check if we should run based on last run time and schedule
    last_run = IndexingRun.latest_for_indexer(indexer_class.name)

    # If never run, should run
    return true unless last_run&.completed_at

    # Check schedule if specified
    schedule = config["schedule"]
    return true unless schedule

    # Parse cron schedule and check if it's time to run
    # For now, just use a simple time-based check
    interval_hours = extract_interval_from_schedule(schedule)
    return true unless interval_hours

    # Check if enough time has passed
    last_run.completed_at < interval_hours.hours.ago
  end

  def extract_interval_from_schedule(schedule)
    # Simple parser for common cron patterns
    # "0 */6 * * *" -> 6 hours
    # "0 */8 * * *" -> 8 hours
    # etc.

    if schedule =~ %r{0 \*/(\d+) \* \* \*}
      ::Regexp.last_match(1).to_i
    end
  end
end
