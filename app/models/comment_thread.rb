# frozen_string_literal: true
# shareable_constant_value: literal

# == Schema Information
#
# Table name: comment_threads
#
#  id               :bigint           not null, primary key
#  comments_count   :integer          default(0), not null
#  commontable_type :string(255)      not null
#  locked_at        :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  commontable_id   :bigint           not null
#
# Indexes
#
#  idx_comment_threads_poly  (commontable_type,commontable_id) UNIQUE
#
class CommentThread < ApplicationRecord
  belongs_to :commontable, polymorphic: true
  has_many :comments, dependent: :destroy

  scope :for, ->(record) { find_or_create_by!(commontable: record) }

  def locked?
    locked_at.present?
  end
end
