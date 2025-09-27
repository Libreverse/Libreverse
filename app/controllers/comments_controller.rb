class CommentsController < ApplicationController
  before_action :require_account!
  before_action :reject_guest!
  before_action :enforce_rate_limit, only: :create
  before_action :load_thread
  before_action :set_comment, only: %i[like approve reject]

  def create
    @comment = @thread.comments.build(comment_params.merge(account_id: current_account.id))
    apply_moderation(@comment)
    if @comment.save
      respond_to do |format|
        if @comment.approved?
          format.turbo_stream
          format.html { redirect_back fallback_location: main_app.root_path, notice: "Comment posted." }
        else
          # Pending comments are hidden; provide minimal feedback only via HTML redirect.
          format.turbo_stream { head :ok }
          format.html { redirect_back fallback_location: main_app.root_path, notice: "Comment submitted for moderation." }
        end
      end
    else
      render status: :unprocessable_entity, plain: @comment.errors.full_messages.join(", ")
    end
  end

  def like
    return head :forbidden unless @comment.approved?

    @comment.likes.find_or_create_by!(account_id: current_account.id)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: main_app.root_path }
    end
  end

  def approve
    authorize_moderator!
    @comment.approve!(approver: current_account)
    respond_to do |format|
      format.turbo_stream { render partial: "comments/comment", formats: [ :html ], locals: { comment: @comment } }
      format.html { redirect_back fallback_location: main_app.root_path, notice: "Comment approved." }
    end
  end

  def reject
    authorize_moderator!
    @comment.reject!(reason: params[:reason])
    respond_to do |format|
      format.turbo_stream { head :ok }
      format.html { redirect_back fallback_location: main_app.root_path, notice: "Comment rejected." }
    end
  end

  private

  def load_thread
    commontable = find_commontable
    @thread = CommentThread.find_or_create_by!(commontable: commontable)
  end

  def find_commontable
    # For now support CMS pages only; extendable later
    raise ActiveRecord::RecordNotFound, "Unsupported commontable_type" unless params[:commontable_type] == "Comfy::Cms::Page"

      Comfy::Cms::Page.find(params[:commontable_id])
  end

  def set_comment
    @comment = @thread.comments.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:body, :parent_id)
  end

  def require_account!
    head :unauthorized unless current_account
  end

  def reject_guest!
    head :forbidden if current_account&.guest?
  end

  def authorize_moderator!
    head :forbidden unless current_account.respond_to?(:admin?) && current_account.admin?
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

  RATE_LIMIT_WINDOW_SECONDS = 10 * 60
  RATE_LIMIT_MAX = 5

  def enforce_rate_limit
    return if current_account.respond_to?(:admin?) && current_account.admin?

    recent_count = Comment.where(account_id: current_account.id)
                          .where("created_at >= ?", RATE_LIMIT_WINDOW_SECONDS.seconds.ago)
                          .count
    return unless recent_count >= RATE_LIMIT_MAX

    respond_to do |format|
      format.turbo_stream { head :too_many_requests }
      format.html { redirect_back fallback_location: main_app.root_path, alert: "Rate limit reached. Please wait before commenting again." }
    end
  end
end
