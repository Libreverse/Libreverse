# frozen_string_literal: true

class CommentThread < ApplicationRecord
  belongs_to :commontable, polymorphic: true
  has_many :comments, dependent: :destroy

  scope :for, ->(record) { find_or_create_by!(commontable: record) }

  def locked?
    locked_at.present?
  end
end
