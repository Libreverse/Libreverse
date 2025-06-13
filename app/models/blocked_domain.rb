# frozen_string_literal: true

# Model for tracking blocked federation domains
class BlockedDomain < ApplicationRecord
  validates :domain, presence: true, uniqueness: true
  validates :blocked_at, presence: true

  scope :recent, -> { order(blocked_at: :desc) }

  def self.blocked?(domain)
    exists?(domain: domain)
  end
end
