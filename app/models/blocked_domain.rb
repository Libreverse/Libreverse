# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# Model for tracking blocked federation domains
# == Schema Information
#
# Table name: blocked_domains
#
#  id         :bigint           not null, primary key
#  blocked_at :datetime         not null
#  blocked_by :string(255)
#  domain     :string(255)      not null
#  reason     :text(65535)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_blocked_domains_on_domain  (domain) UNIQUE
#
class BlockedDomain < ApplicationRecord
  before_validation { self.domain = domain&.downcase }
  validates :domain,
            presence: true,
            uniqueness: true,
            format: { with: /\A[a-z0-9.-]+\z/, message: "invalid domain" }
  validates :blocked_at, presence: true
  validates :blocked_by, :domain, length: { maximum: 255 }, allow_blank: true
  validates :reason, length: { maximum: 65_535 }, allow_blank: true

  scope :recent, -> { order(blocked_at: :desc) }

  def self.blocked?(domain)
    exists?(domain: domain)
  end
end
