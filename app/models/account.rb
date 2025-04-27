# frozen_string_literal: true

require "sequel/model"

# Sequel model for Rodauth and Sequel-specific logic
class AccountSequel < Sequel::Model(:accounts)
  plugin :timestamps, update_on_create: true

  # Sequel associations
  one_to_many :user_preferences, key: :account_id
  one_to_many :experiences, key: :account_id

  # Status helpers (replace enum)
  def unverified?
    status == 1
  end

  def verified?
    status == 2
  end

  def closed?
    status == 3
  end

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

  # Sequel column encryption for Rodauth tables
  # Removed encryption for password_hash (should not be encrypted)

  # Nested Sequel models for remember and password reset keys
  if defined?(SEQUEL_COLUMN_ENCRYPTION_KEY)
    if DB.table_exists?(:account_remember_keys)
      class RememberKey < Sequel::Model(:account_remember_keys)
        plugin :column_encryption do |enc|
          enc.key 0, SEQUEL_COLUMN_ENCRYPTION_KEY
          enc.column :key, searchable: true
        end
      end
    end

    if DB.table_exists?(:account_password_reset_keys)
      class PasswordResetKey < Sequel::Model(:account_password_reset_keys)
        plugin :column_encryption do |enc|
          enc.key 0, SEQUEL_COLUMN_ENCRYPTION_KEY
          enc.column :key, searchable: true
        end
      end
    end
  end
end

# ActiveRecord bridge for associations
class Account < ApplicationRecord
  self.table_name = "accounts"

  # Add any AR-specific logic or validations here if needed
end
