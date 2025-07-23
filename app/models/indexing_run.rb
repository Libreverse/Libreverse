# frozen_string_literal: true

class IndexingRun < ApplicationRecord
  # JSON serialization for SQLite compatibility
  serialize :configuration, coder: JSON
  serialize :error_details, coder: JSON

  # Enums - Rails 8 syntax
  enum :status, {
    pending: 0,
    running: 1,
    completed: 2,
    failed: 3
  }

  # Validations
  validates :indexer_class, presence: true
  validates :status, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :successful, -> { where(status: :completed) }
  scope :for_indexer, ->(indexer_class) { where(indexer_class: indexer_class) }

  # Class methods
  def self.latest_for_indexer(indexer_class)
    for_indexer(indexer_class).recent.first
  end

  def self.success_rate_for_indexer(indexer_class)
    runs = for_indexer(indexer_class)
    return 0 if runs.empty?

    successful_count = runs.successful.count
    total_count = runs.count
    ((successful_count.to_f / total_count) * 100).round(1)
  end

  # Instance methods
  def indexer_platform_name
    # Extract platform name from class name
    # e.g., "Metaverse::DecentralandIndexer" -> "decentraland"
    indexer_class.split("::").last.gsub("Indexer", "").underscore
  end

  def duration
    return 0 unless started_at

    end_time = completed_at || Time.current
    end_time - started_at
  end

  def duration_formatted
    dur = duration
    if dur < 60
      "#{dur.round(1)}s"
    elsif dur < 3600
      "#{(dur / 60).round(1)}m"
    else
      "#{(dur / 3600).round(1)}h"
    end
  end

  def success_rate
    total_items = items_processed + items_failed
    return 0.0 if total_items.zero?

    ((items_processed.to_f / total_items) * 100).round(1)
  end

  def configuration_hash
    configuration || {}
  end

  def error_details_hash
    error_details || {}
  end
end
