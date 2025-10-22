class CommentLike < ApplicationRecord
  belongs_to :comment
  counter_culture :comment
  validates :account_id, presence: true
end
