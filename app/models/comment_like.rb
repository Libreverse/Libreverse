# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# == Schema Information
#
# Table name: comment_likes
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  comment_id :bigint           not null
#
# Indexes
#
#  index_comment_likes_on_comment_id                 (comment_id)
#  index_comment_likes_on_comment_id_and_account_id  (comment_id,account_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (comment_id => comments.id)
#
class CommentLike < ApplicationRecord
  belongs_to :comment
  counter_culture :comment
  validates :account_id, presence: true
end
