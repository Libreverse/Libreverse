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

    private

    def set_comment
      @comment = Comment.find(params[:id])
    end
  end
end
