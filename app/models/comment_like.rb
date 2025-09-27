class CommentLike < ApplicationRecord
  belongs_to :comment
  validates :account_id, presence: true

  after_commit :recount_likes, on: %i[create destroy]

  private

  def recount_likes
    Comment.where(id: comment_id).update_all(likes_count: CommentLike.where(comment_id: comment_id).count)
  end
end
