# frozen_string_literal: true
# shareable_constant_value: literal

module Admin
  # Controller for managing Experiences within the Admin namespace.
  class ExperiencesController < BaseController
    before_action :set_experience, only: [ :approve ]

    # GET /admin/experiences
    # Lists experiences pending approval.
    def index
      # Assuming Experience model has a `pending_approval` scope
      @experiences = Experience.pending_approval.order(created_at: :desc)
    end

    private

    # Finds the Experience based on the ID parameter.
    def set_experience
      @experience = Experience.friendly.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      @experience = Experience.find_by(id: params[:id])
      redirect_to admin_experiences_path, alert: "Experience not found." unless @experience
    end
  end
end
