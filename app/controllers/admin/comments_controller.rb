# frozen_string_literal: true
# shareable_constant_value: literal

module Admin
  class CommentsController < BaseController
    before_action :set_comment, only: %i[approve reject]

    def index
      @q = params[:q].to_s.strip
      scope = Comment.where(moderation_state: %w[pending rejected])
      scope = scope.where("body LIKE ?", "%#{@q}%") if @q.present?
      @state = params[:state].presence
      scope = scope.where(moderation_state: @state) if @state.present?
      @comments = scope.order(created_at: :asc).limit(500).includes(:thread)
      @counts = Comment.group(:moderation_state).count.slice("pending", "rejected", "approved")
    end

    def approve
      @comment.approve!(approver: current_account)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: admin_comments_path, notice: "Comment approved." }
      end
    end

    def reject
      @comment.reject!(reason: params[:reason])
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: admin_comments_path, notice: "Comment rejected." }
      end
    end

    def bulk
      ids = Array(params[:comment_ids]).map(&:to_i).uniq
      action = params[:moderation_action]
      comments = Comment.where(id: ids)
      case action
      when "approve"
        comments.find_each { |c| c.approve!(approver: current_account) }
        flash[:notice] = "Approved #{comments.size} comments"
      when "reject"
        comments.find_each { |c| c.reject!(reason: params[:reason]) }
        flash[:notice] = "Rejected #{comments.size} comments"
      else
        flash[:alert] = "No valid action specified"
      end
      redirect_to admin_comments_path
    end

    private

    def set_comment
      @comment = Comment.find(params[:id])
    end
  end
end
