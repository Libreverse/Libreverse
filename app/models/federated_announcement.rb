# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

# Model for storing announcements of federated experiences (links only, no content)
# == Schema Information
#
# Table name: federated_announcements
#
#  id              :bigint           not null, primary key
#  activitypub_uri :string(255)      not null
#  announced_at    :datetime         not null
#  experience_url  :string(255)
#  source_domain   :string(255)      not null
#  title           :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_federated_announcements_on_activitypub_uri  (activitypub_uri) UNIQUE
#  index_federated_announcements_on_announced_at     (announced_at)
#  index_federated_announcements_on_source_domain    (source_domain)
#
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
