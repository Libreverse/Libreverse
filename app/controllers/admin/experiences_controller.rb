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

    # POST /admin/experiences/add_examples
    # Adds example experiences to the database
    def add_examples
        result = ExampleExperiencesService.add_examples
        redirect_to admin_experiences_path, notice: "Successfully created #{result[:created]} example experiences."
    rescue StandardError => e
        redirect_to admin_experiences_path, alert: "Failed to add examples: #{e.message}"
    end

    # POST /admin/experiences/restore_examples
    # Restores example experiences to their default state
    def restore_examples
        result = ExampleExperiencesService.restore_examples
        redirect_to admin_experiences_path, notice: "Successfully restored #{result[:restored]} example experiences."
    rescue StandardError => e
        redirect_to admin_experiences_path, alert: "Failed to restore examples: #{e.message}"
    end

    # DELETE /admin/experiences/delete_examples
    # Deletes all example experiences
    def delete_examples
        result = ExampleExperiencesService.delete_examples
        redirect_to admin_experiences_path, notice: "Successfully deleted #{result[:deleted]} example experiences."
    rescue StandardError => e
        redirect_to admin_experiences_path, alert: "Failed to delete examples: #{e.message}"
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
