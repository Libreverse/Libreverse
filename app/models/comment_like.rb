# frozen_string_literal: true
# shareable_constant_value: literal

class CommentLike < ApplicationRecord
  belongs_to :comment
  counter_culture :comment
  validates :account_id, presence: true
end
