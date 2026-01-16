# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

# Model for tracking blocked federated experiences
# == Schema Information
#
# Table name: blocked_experiences
#
#  id              :bigint           not null, primary key
#  activitypub_uri :string(255)      not null
#  blocked_at      :datetime         not null
#  blocked_by      :string(255)
#  reason          :text(65535)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_blocked_experiences_on_activitypub_uri  (activitypub_uri) UNIQUE
#
class BlockedExperience < ApplicationRecord
  validates :activitypub_uri, presence: true, uniqueness: true
  validates :blocked_at, presence: true

  scope :recent, -> { order(blocked_at: :desc) }

  def self.blocked?(uri)
    exists?(activitypub_uri: uri)
  end
end
