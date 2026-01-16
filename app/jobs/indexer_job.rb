# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# Background job for running individual indexers
class IndexerJob < ApplicationJob
  queue_as :default

  # Retry failed jobs with exponential backoff
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  # Set a reasonable timeout to prevent jobs from running indefinitely
  MAX_RUNTIME_SECONDS = 4 * 3600

  def perform(indexer_class_name, options = {})
    Rails.logger.info "Starting IndexerJob for #{indexer_class_name}"

    # Set up timeout protection
    start_time = Time.current

    # Load the indexer class
    indexer_class = indexer_class_name.constantize
    indexer = indexer_class.new(options)

    # Run the indexing process with timeout protection
    Timeout.timeout(MAX_RUNTIME_SECONDS) do
      indexer.index!
    end

    runtime = Time.current - start_time
    Rails.logger.info "Completed IndexerJob for #{indexer_class_name} in #{runtime.round(2)} seconds"
  rescue Timeout::Error
    runtime = Time.current - start_time
    Rails.logger.error "IndexerJob for #{indexer_class_name} timed out after #{runtime.round(2)} seconds (max: #{MAX_RUNTIME_SECONDS} seconds)"
    raise "Indexing timed out after #{MAX_RUNTIME_SECONDS} seconds"
  rescue StandardError => e
    Rails.logger.error "IndexerJob failed for #{indexer_class_name}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    # Re-raise to trigger retry mechanism
    raise
  end
end
