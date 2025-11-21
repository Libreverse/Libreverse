# frozen_string_literal: true
# shareable_constant_value: literal

# Model for storing announcements of federated experiences (links only, no content)
class FederatedAnnouncement < ApplicationRecord
  validates :activitypub_uri, presence: true, uniqueness: true
  validates :source_domain, presence: true
  validates :announced_at, presence: true

  scope :recent, -> { order(announced_at: :desc) }
  scope :from_domain, ->(domain) { where(source_domain: domain) }

  # Clean up old announcements to prevent table bloat
  scope :old, -> { where("announced_at < ?", 30.days.ago) }

  def self.cleanup_old_announcements
    old.delete_all
  end

  def federated_experience_link
    # Return a link object that can be used in search results
    OpenStruct.new(
      title: title,
      activitypub_uri: activitypub_uri,
      experience_url: experience_url,
      source_domain: source_domain,
      federated?: true,
      announced_at: announced_at
    )
  end
end
