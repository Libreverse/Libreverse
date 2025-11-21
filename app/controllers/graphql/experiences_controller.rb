# frozen_string_literal: true
# shareable_constant_value: literal

module Graphql
  class ExperiencesController < GraphqlApplicationController
    model("Experience")

    # Queries
    action(:index).permit(limit: "Int", approved_only: "Boolean").returns("[Experience!]!")
    action(:show).permit(id: "ID!").returns("Experience")
    action(:approved).permit(limit: "Int").returns("[Experience!]!")
    action(:pending_approval).permit(limit: "Int").returns("[Experience!]!")

    # Mutations
    action(:create).permit(
      title: "String!",
      description: "String",
      html_content: "String",
      author: "String"
    ).returns("Experience!")
    action(:update).permit(
      id: "ID!",
      title: "String",
      description: "String",
      author: "String",
      federate: "Boolean"
    ).returns("Experience!")
    action(:destroy).permit(id: "ID!").returns("Boolean")
    action(:approve).permit(id: "ID!").returns("Experience!")

    def index
      # Admins see all experiences if approved_only is not explicitly true
      experiences = if current_account&.admin? && !params[:approved_only]
        Experience.order(created_at: :desc)
      else
        Experience.approved.order(created_at: :desc)
      end

      limit = [ params[:limit] || 20, 100 ].min
      experiences.limit(limit)
    end

    def show
      experience = if current_account&.admin?
        Experience.find_by(id: params[:id])
      else
        Experience.approved.find_by(id: params[:id])
      end

      raise GraphqlRails::ExecutionError, "Experience not found" unless experience

      experience
    end

    def approved
      limit = [ params[:limit] || 20, 100 ].min
      Experience.approved.order(created_at: :desc).limit(limit)
    end

    def pending_approval
      require_authentication

      # Admin sees all pending experiences, users see only their own
      experiences = if current_account.admin?
        Experience.pending_approval.order(created_at: :desc)
      else
        Experience.where(account_id: current_account.id, approved: false).order(created_at: :desc)
      end

      limit = [ params[:limit] || 20, 100 ].min
      experiences.limit(limit)
    end

    def create
      require_authentication

      experience = Experience.new(
        title: params[:title],
        description: params[:description],
        author: params[:author] || current_account.username,
        account_id: current_account.id,
        federate: true # User experiences are always federated
      )

      if params[:html_content].present?
        experience.html_file.attach(
          io: StringIO.new(params[:html_content]),
          filename: "experience_#{Time.current.to_i}.html",
          content_type: "text/html"
        )
      end

      raise GraphqlRails::ExecutionError, "Failed to create experience: #{experience.errors.full_messages.join(', ')}" unless experience.save

        experience
    end

    def update
      require_authentication

      experience = Experience.find_by(id: params[:id], account_id: current_account.id)
      raise GraphqlRails::ExecutionError, "Experience not found or not owned by current user" unless experience

      update_params = {}
      update_params[:title] = params[:title] if params[:title]
      update_params[:description] = params[:description] if params[:description]
      update_params[:author] = params[:author] if params[:author]
      # User experiences remain federated regardless of API input
      update_params[:federate] = true

      raise GraphqlRails::ExecutionError, "Failed to update experience: #{experience.errors.full_messages.join(', ')}" unless experience.update(update_params)

        experience
    end

    def destroy
      require_authentication

      experience = Experience.find_by(id: params[:id], account_id: current_account.id)
      raise GraphqlRails::ExecutionError, "Experience not found or not owned by current user" unless experience

      raise GraphqlRails::ExecutionError, "Failed to delete experience" unless experience.destroy

        true
    end

    def approve
      require_admin

      experience = Experience.find_by(id: params[:id])
      raise GraphqlRails::ExecutionError, "Experience not found" unless experience

      raise GraphqlRails::ExecutionError, "Failed to approve experience: #{experience.errors.full_messages.join(', ')}" unless experience.update(approved: true)

        experience
    end
  end
end
