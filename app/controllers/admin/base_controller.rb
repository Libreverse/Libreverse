# frozen_string_literal: true

# Base controller for all controllers in the Admin namespace.
# Ensures that only authenticated administrators can access admin sections.
module Admin
  class BaseController < ApplicationController
    layout "admin" # Optional: Use a specific layout for admin pages

    before_action :authenticate_admin!

    private

    # Verifies that the current user is logged in and is an administrator.
    # Redirects to the root path with an alert if not authorized.
    # Assumes `rodauth.logged_in?` checks authentication and `current_account.admin?` checks authorization.
    def authenticate_admin!
      return if rodauth.logged_in? && current_account&.admin?

        redirect_to root_path, alert: "You are not authorized to access this page."
    end
  end
end
