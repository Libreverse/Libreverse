# frozen_string_literal: true

class Account < ApplicationRecord
  include Rodauth::Rails.model
  enum :status, { unverified: 1, verified: 2, closed: 3 }
  has_many :user_preferences, dependent: :destroy
  has_many :experiences, dependent: :destroy

  # Check if this account is a guest account
  def guest?
    guest == true
  end

  # Determines if the account is an admin
  def admin?
    admin == true
  end

  # before_validation :assign_first_admin, on: :create # Removed - Handled in RodauthMain.after_create_account

  # private # Removed private section as method is gone

  # Assign the first non‑guest account as an admin # Removed method
  # def assign_first_admin
  #   Rails.logger.debug "[assign_first_admin] Running for account ID: #{id || 'new'}"
  #   Rails.logger.debug "[assign_first_admin] guest? is: #{guest?}"
  #   admin_exists = Account.where(admin: true).exists?
  #   Rails.logger.debug "[assign_first_admin] Account.where(admin: true).exists? is: #{admin_exists}"
  #
  #   return if guest?
  #   return if admin_exists # Use the stored value to avoid double query
  #
  #   Rails.logger.info "[assign_first_admin] Assigning admin role to account ID: #{id || 'new'}"
  #   self.admin = true
  # end
end
