# frozen_string_literal: true

# Base controller for all controllers in the Admin namespace.
# Ensures that only authenticated administrators can access admin sections.
module Admin
  class BaseController < ApplicationController
    layout "admin" # Optional: Use a specific layout for admin pages

    # Use CanCanCan authorization
    authorize_resource class: false
    before_action :authenticate_admin!

    private

    # Verifies that the current user is logged in and is an administrator.
    # Uses the new role-based authentication system
    def authenticate_admin!
      return if authenticated_user? && current_account&.admin?

        flash[:alert] = "You must be an admin to access this page."
        redirect_to root_path
    end
  end
end
