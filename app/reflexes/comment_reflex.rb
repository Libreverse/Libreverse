# frozen_string_literal: true

class CommentReflex < ApplicationReflex
  def create
    thread = load_thread
    comment = thread.comments.build(comment_params.merge(account_id: current_account.id))
    
    apply_moderation(comment)
    
    if comment.save
      if comment.approved?
        morph "#comment-thread-#{thread.id}", render(partial: "comments/thread", locals: { thread: thread })
        morph "#comment-form-#{thread.id}", render(partial: "comments/form", locals: { thread: thread })
      else
        morph "#comment-form-#{thread.id}", render(partial: "comments/pending_notice")
      end
    else
      # Render form with errors
      morph "#comment-form-#{thread.id}", render(partial: "comments/form", locals: { thread: thread, comment: comment })
    end
  end

  def like
    comment = Comment.find(element.dataset[:id])
    return unless comment.approved?

    comment.likes.find_or_create_by!(account_id: current_account.id)
    
    # Refresh just the comment meta/likes
    morph "#comment-#{comment.id} .likes", "Likes: #{comment.likes_count}"
    # Or simpler, just re-render the whole comment if needed, but granular is better.
    # For now, let's re-render the comment partial to be safe with layout
    morph "#comment-#{comment.id}", render(partial: "comments/comment", locals: { comment: comment.reload })
  end

  def approve
    authorize_moderator!
    comment = Comment.find(element.dataset[:id])
    comment.approve!(approver: current_account)
    morph "#comment-#{comment.id}", render(partial: "comments/comment", locals: { comment: comment })
  end

  def reject
    authorize_moderator!
    comment = Comment.find(element.dataset[:id])
    comment.reject!(reason: element.dataset[:reason])
    morph "#comment-#{comment.id}", ""
  end

  private

  def load_thread
    commontable_type = element.dataset[:commontable_type]
    commontable_id = element.dataset[:commontable_id]
    
    raise ActiveRecord::RecordNotFound, "Unsupported commontable_type" unless commontable_type == "Comfy::Cms::Page"
    
    commontable = Comfy::Cms::Page.find(commontable_id)
    CommentThread.find_or_create_by!(commontable: commontable)
  end

  def comment_params
    params.require(:comment).permit(:body, :parent_id)
  end

  def apply_moderation(comment)
    body = comment.body.to_s
    if ModerationService.contains_inappropriate_content?(body)
      comment.moderation_state = "rejected"
      comment.moderation_flags = { auto: true, violation_details: ModerationService.get_violation_details(body) }
    else
      # Even if clean, still require manual approval (pending) per requirements
      comment.moderation_state = "pending"
    end
  end

  def authorize_moderator!
    raise "Unauthorized" unless current_account.respond_to?(:admin?) && current_account.admin?
  end
end
