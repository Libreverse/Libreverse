# frozen_string_literal: true

# Background job for running individual indexers
class IndexerJob < ApplicationJob
  queue_as :default

  # Retry failed jobs with exponential backoff
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(indexer_class_name, options = {})
    Rails.logger.info "Starting IndexerJob for #{indexer_class_name}"

    # Load the indexer class
    indexer_class = indexer_class_name.constantize
    indexer = indexer_class.new(options)

    # Run the indexing process
    indexer.index!

    Rails.logger.info "Completed IndexerJob for #{indexer_class_name}"
  rescue StandardError => e
    Rails.logger.error "IndexerJob failed for #{indexer_class_name}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    # Re-raise to trigger retry mechanism
    raise
  end
end
