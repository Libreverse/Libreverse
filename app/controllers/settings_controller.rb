# frozen_string_literal: true

class SettingsController < ApplicationController
  before_action :require_authentication

  def index
    # Only user-specific preferences remain here
    # Instance-wide settings like automoderation and EEA mode are now admin-only
  end

  private

  def require_authentication
    return if current_account

      flash[:alert] = "You must be logged in to access settings."
      redirect_to "/login"
  end
end
