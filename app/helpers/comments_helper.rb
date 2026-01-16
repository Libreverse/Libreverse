# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

module CommentsHelper
  def render_comment_thread(commontable)
    thread = CommentThread.find_or_create_by!(commontable: commontable)
    render partial: "comments/thread", locals: { thread: thread, commontable: commontable }
  end

  def comment_like_button(comment)
    turbo_stream_from "comment_#{comment.id}_likes"
    button_to "Like", like_comment_path(comment, commontable_type: comment.thread.commontable_type, commontable_id: comment.thread.commontable_id), method: :post, data: { turbo_stream: true }, class: "comment-like-button"
  end
end
