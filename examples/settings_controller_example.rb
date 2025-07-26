# frozen_string_literal: true

# Example: Settings Controller with Role-Based Access

class SettingsController < ApplicationController
  # CanCanCan authorization
  load_and_authorize_resource :account, parent: false

  # Require authenticated users (no guests) for all settings
  before_action :require_authenticated_user
  before_action :ensure_own_account

  def show
    # User can view their own settings
    @account = current_account
    @user_preferences = current_account.user_preferences
  end

  def update
    # User can update their own settings
    @account = current_account

    if @account.update(account_params)
      # If guest status changed, reassign roles
      @account.assign_default_role if @account.saved_change_to_guest?

      flash[:success] = "Settings updated successfully!"
      redirect_to settings_path
    else
      render :show
    end
  end

  def destroy
    # User can delete their own account (but not admins)
    if current_account.admin?
      flash[:error] = "Admin accounts cannot be self-deleted."
      redirect_to settings_path
    else
      current_account.destroy
      session[:account_id] = nil
      flash[:success] = "Account deleted successfully."
      redirect_to root_path
    end
  end

  private

  def account_params
    # Don't allow users to change admin status or guest status directly
    # (guest status should be handled through separate upgrade process)
    params.require(:account).permit(:username, :password, :password_confirmation)
  end

  def ensure_own_account
    # Extra security: ensure users can only access their own settings
    return if params[:id].nil? || params[:id].to_i == current_account.id

      flash[:error] = "You can only access your own settings."
      redirect_to settings_path
  end
end

# In your Ability class, you would have:
# can :manage, Account, id: user.id  # Users can manage their own account
