# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# == Schema Information
#
# Table name: comments
#
#  id                :bigint           not null, primary key
#  approved_at       :datetime
#  body              :text(65535)      not null
#  deleted_at        :datetime
#  edited_at         :datetime
#  likes_count       :integer          default(0), not null
#  mentions_cache    :json             not null
#  moderation_flags  :json
#  moderation_state  :string(255)      default("pending"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  approved_by_id    :bigint
#  comment_thread_id :bigint           not null
#  parent_id         :bigint
#
# Indexes
#
#  index_comments_on_account_id         (account_id)
#  index_comments_on_comment_thread_id  (comment_thread_id)
#  index_comments_on_moderation_state   (moderation_state)
#  index_comments_on_parent_id          (parent_id)
#
# Foreign Keys
#
#  fk_rails_...  (comment_thread_id => comment_threads.id)
#
class Comment < ApplicationRecord
  has_closure_tree

  belongs_to :thread, class_name: "CommentThread", foreign_key: :comment_thread_id, counter_cache: true
  begin
    belongs_to :account, class_name: "Account", optional: false, inverse_of: false
  rescue StandardError
    nil
  end
  has_many :likes, class_name: "CommentLike", dependent: :destroy

  scope :root, -> { where(parent_id: nil) }
  scope :visible, -> { where(deleted_at: nil) }
  scope :ordered_by_likes, -> { order(likes_count: :desc, created_at: :asc) }

  # ClosureTree convenience methods
  scope :with_descendants, -> { includes(:descendants) }
  scope :threaded, -> { includes(:children, :parent) }

  validates :body, presence: true, length: { maximum: 10_000 }
  validates :moderation_state, inclusion: { in: %w[pending rejected approved] }

  before_validation :ensure_defaults, :extract_mentions
  before_validation :set_initial_moderation_state

  def extract_mentions
    usernames = body.to_s.scan(/@([A-Za-z0-9_]{3,30})/).flatten.uniq
    return if usernames.empty?

    ids = AccountSequel.where(username: usernames).select_map(:id)
    self.mentions_cache = ids
  end

  def ensure_defaults
    self.mentions_cache ||= []
  end

  def set_initial_moderation_state
    self.moderation_state ||= "pending"
  end

  def approved?
    moderation_state == "approved"
  end

  def reject!(reason: nil)
    update!(moderation_state: "rejected", moderation_flags: { reason: reason, at: Time.current })
  end

  def approve!(approver: nil)
    update!(moderation_state: "approved", approved_at: Time.current, approved_by_id: approver&.id)
  end

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  # ClosureTree convenience methods
  def thread_root
    root
  end

  def reply_count
    descendants.visible.count
  end

  def thread_depth
    ancestors.count
  end

  def full_thread
    self_and_descendants.visible.ordered_by_likes
  end
end
