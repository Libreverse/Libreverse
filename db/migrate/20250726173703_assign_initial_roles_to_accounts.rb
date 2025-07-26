# frozen_string_literal: true

class AssignInitialRolesToAccounts < ActiveRecord::Migration[8.0]
  def up
    # Create the basic roles first
    Role.find_or_create_by(name: 'guest')
    Role.find_or_create_by(name: 'user')
    Role.find_or_create_by(name: 'admin')

    # Assign roles to existing accounts
    Account.find_each do |account|
      if account.guest?
        account.add_role(:guest) unless account.has_role?(:guest)
      else
        account.add_role(:user) unless account.has_role?(:user)
      end

      # Assign admin role to existing admin accounts
      account.add_role(:admin) if account.admin? && !account.has_role?(:admin)
    end
  end

  def down
    # Remove all role assignments
    Account.find_each do |account|
      account.roles.clear
    end

    # Optionally remove the roles themselves
    Role.where(name: %w[guest user admin]).destroy_all
  end
end
