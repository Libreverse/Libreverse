# frozen_string_literal: true
# shareable_constant_value: literal

class Ability
  include CanCan::Ability

  def initialize(user)
    # Ensure Experience model is loaded for authorization
    # (load_and_authorize_resource needs this)

    # Start with no permissions
    user ||= Account.new # guest user (not logged in)

    # Basic permissions that all visitors get (even non-logged in)
    can :read, :public_content

  # Guest users (logged in but with guest account)
  # NOTE: ActiveRecord models expose new_record?/persisted? (not new?).
  # An unsaved placeholder Account (user=nil case) will have persisted? == false.
  if user.persisted? && user.guest?
      # Limited permissions for guest accounts
      can :read, :public_content
      can :create, :guest_session
      can :read, Experience # Can view experiences but not create/edit
      can :display, Experience
      can :access, :dashboard  # Can view dashboard but with limited features
      can :read, :settings     # Allow access to settings (language, preferences)
      can :update, :settings   # Allow updating basic settings like language
      cannot :create, Experience
      cannot :update, Experience
      cannot :destroy, Experience
      cannot :access, :admin_area
      cannot :export, :account_data

    # Regular authenticated users (non-guest)
  elsif user.persisted? && user.has_role?(:user)
      # Full user permissions
      can :manage, Account, id: user.id # Can manage their own account
      can :read, :all
      can :create, %i[post comment experience]
      can :update, %i[post comment experience], account_id: user.id
      can :destroy, %i[post comment experience], account_id: user.id
      can :access, :user_area
      can :export, :account_data # Can export their own data

      # Experience-specific permissions
      can :read, Experience
      can :create, Experience
      can :update, Experience, account_id: user.id
      can :destroy, Experience, account_id: user.id
      can :display, Experience

      # Settings and preferences
      can :read, :settings
      can :update, :settings
      can :access, :dashboard

      # Admin permissions
      if user.admin?
        can :manage, :all
        can :access, :admin_area
        can :approve, Experience
      end

    # Non-logged in users
  else
      # Very basic permissions for completely unauthenticated users
      can :read, :public_content
      can :create, :account  # Allow account creation
      can :create, :session  # Allow login
      cannot :access, :user_area
      cannot :access, :admin_area
  end
  end
end
