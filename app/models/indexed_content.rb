# frozen_string_literal: true

class IndexedContent < ApplicationRecord
  # JSON serialization for SQLite compatibility
  serialize :metadata, coder: JSON
  serialize :coordinates, coder: JSON

  # Validations
  validates :source_platform, presence: true
  validates :external_id, presence: true
  validates :content_type, presence: true
  validates :source_platform, :external_id, uniqueness: { scope: :source_platform }

  # Scopes
  scope :by_platform, ->(platform) { where(source_platform: platform) }
  scope :by_content_type, ->(type) { where(content_type: type) }
  scope :recently_indexed, -> { where("last_indexed_at > ?", 24.hours.ago) }
  scope :needs_update, -> { where("last_indexed_at < ? OR last_indexed_at IS NULL", 24.hours.ago) }

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
end
