# frozen_string_literal: true

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

    # PATCH /admin/experiences/:id/approve
    # Marks an experience as approved.
    def approve
      if @experience.update(approved: true)
        # Consider adding a more specific redirect or Turbo Stream update later
        redirect_to admin_experiences_path, notice: "Experience '#{@experience.title}' approved successfully."
      else
        # Handle potential errors during approval
        redirect_to admin_experiences_path, alert: "Failed to approve experience: #{@experience.errors.full_messages.join(', ')}"
      end
    end

    private

    # Finds the Experience based on the ID parameter.
    def set_experience
      @experience = Experience.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_experiences_path, alert: "Experience not found."
    end
  end
end
