class SettingsController < ApplicationController
  # Allow both guests and users to access settings (for language, basic preferences)
  before_action :require_authentication
  before_action :authorize_settings_access

  def index
    # Both guests and users can access basic settings
    @account = current_account
  end

  private

  def authorize_settings_access
    return if can?(:read, :settings)

      flash[:alert] = "You don't have permission to access settings."
      redirect_to root_path
  end
end
