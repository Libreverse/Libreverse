# frozen_string_literal: true
# shareable_constant_value: literal

# == Schema Information
#
# Table name: indexed_contents
#
#  id              :bigint           not null, primary key
#  author          :string(255)
#  content_type    :string(255)      not null
#  coordinates     :text(65535)
#  description     :text(65535)
#  last_indexed_at :datetime
#  metadata        :text(4294967295)
#  source_platform :string(255)      not null
#  title           :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  external_id     :string(255)      not null
#
# Indexes
#
#  index_indexed_contents_on_content_type                     (content_type)
#  index_indexed_contents_on_last_indexed_at                  (last_indexed_at)
#  index_indexed_contents_on_source_platform                  (source_platform)
#  index_indexed_contents_on_source_platform_and_external_id  (source_platform,external_id) UNIQUE
#
class IndexedContent < ApplicationRecord
  # Enable SecondLevelCache for automatic read-through/write-through caching
  second_level_cache expires_in: 1.hour

  # Associations
  has_one :indexed_content_vector, dependent: :destroy

  # JSON serialization for TiDB compatibility (MySQL-compatible distributed database)
  serialize :metadata, coder: JSON
  serialize :coordinates, coder: JSON

  # Validations
  validates :source_platform, presence: true
  validates :external_id, presence: true
  validates :content_type, presence: true
  validates :external_id, uniqueness: { scope: :source_platform }

  # Scopes
  scope :by_platform, ->(platform) { where(source_platform: platform) }
  scope :by_content_type, ->(type) { where(content_type: type) }
  scope :recently_indexed, -> { where("last_indexed_at > ?", 24.hours.ago) }
  scope :needs_update, -> { where("last_indexed_at < ? OR last_indexed_at IS NULL", 24.hours.ago) }

  # Callbacks
  after_commit :schedule_vectorization, on: %i[create update], if: :should_vectorize?

  # Class methods
  def self.platforms
    distinct.pluck(:source_platform).sort
  end

  def self.content_types
    distinct.pluck(:content_type).sort
  end

  # Instance methods
  def platform_display_name
    source_platform.humanize
  end

  def needs_update?
    last_indexed_at.nil? || last_indexed_at < 24.hours.ago
  end

  def coordinates_hash
    coordinates.is_a?(Hash) ? coordinates : {}
  end

  def metadata_hash
    metadata.is_a?(Hash) ? metadata : {}
  end

  # For search integration
  def to_unified_content
    UnifiedIndexedContent.new(self)
  end

  # Check if this indexed content needs vectorization
  def needs_vectorization?
    # No vector exists
    return true unless indexed_content_vector

    # Vector is outdated
    indexed_content_vector.needs_regeneration?(self)
  end

  # Find similar content using vector search
  def find_similar(limit: 10)
    IndexedContentSearchService.find_related(self, limit: limit)
  end

  # Determine if this content should be vectorized
  def should_vectorize?
    # No vector exists - always needs vectorization
    return true unless indexed_content_vector

    # Check if content has changed since last vectorization
    indexed_content_vector.needs_regeneration?(self)
  end

  # Schedule vectorization job
  def schedule_vectorization
    if Rails.env.development?
      # Run synchronously in development for immediate vector search
      VectorizeIndexedContentJob.perform_now(id)
    else
      # Run asynchronously in production
      VectorizeIndexedContentJob.perform_later(id)
    end
  rescue StandardError => e
    Rails.logger.error "Failed to schedule vectorization for indexed_content #{id}: #{e.message}"
  end
end
