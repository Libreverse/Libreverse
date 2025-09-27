# Model for tracking blocked federated experiences
class BlockedExperience < ApplicationRecord
  validates :activitypub_uri, presence: true, uniqueness: true
  validates :blocked_at, presence: true

  scope :recent, -> { order(blocked_at: :desc) }

  def self.blocked?(uri)
    exists?(activitypub_uri: uri)
  end
end
