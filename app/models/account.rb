# frozen_string_literal: true

require "sequel/model"
require_relative "../services/moderation_service"

# Sequel model for Rodauth and Sequel-specific logic
class AccountSequel < Sequel::Model(:accounts)
  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  # Sequel associations
  one_to_many :user_preferences, key: :account_id
  one_to_many :experiences, key: :account_id

  # Content moderation validation for usernames
  def validate
    super
    validate_username_moderation if username
  end

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

    # Encrypt account verification keys
    if DB.table_exists?(:account_verification_keys)
      class VerificationKey < Sequel::Model(:account_verification_keys)
        plugin :column_encryption do |enc|
          enc.key 0, SEQUEL_COLUMN_ENCRYPTION_KEY
          enc.column :key, searchable: true
        end
      end
    end

    # Encrypt account login change keys (both key and login columns)
    if DB.table_exists?(:account_login_change_keys)
      class LoginChangeKey < Sequel::Model(:account_login_change_keys)
        plugin :column_encryption do |enc|
          enc.key 0, SEQUEL_COLUMN_ENCRYPTION_KEY
          enc.column :key, searchable: true
          enc.column :login, searchable: true
        end
      end
    end
  end

  # Ensure timestamps are set for DBs that don't default them
  def before_create
    self.created_at ||= Time.zone.now if respond_to?(:created_at) && !created_at
    self.updated_at ||= Time.zone.now if respond_to?(:updated_at) && !updated_at
    super
  end

  # Ensure timestamps are set for join tables (e.g., accounts_roles)
  def self.join_table_before_create(row)
    row[:created_at] ||= Time.zone.now if row.respond_to?(:created_at) && !row[:created_at]
    row[:updated_at] ||= Time.zone.now if row.respond_to?(:updated_at) && !row[:updated_at]
    row
  end

  private

  def validate_username_moderation
    return if username.blank?

    return unless ModerationService.contains_inappropriate_content?(username)

    violations = ModerationService.get_violation_details(username)
    log_moderation_violation("username", username, violations)
    errors.add(:username, "contains inappropriate content and cannot be saved")
  end

  def log_moderation_violation(field, _content, violations)
    violations ||= []
    reason = if violations.empty?
      "content flagged by comprehensive moderation system"
    else
      violations.map { |v| "#{v[:type]}#{v[:details] ? " (#{v[:details].join(', ')})" : ''}" }.join("; ")
    end

    # Only log to Rails logger to avoid recursion since Account moderation
    # would trigger when creating ModerationLog records
    Rails.logger.warn "Moderation violation in #{self.class.name} #{field}: #{reason}"

    # NOTE: We don't log Account violations to database to avoid infinite recursion
    # since the ModerationLog belongs_to :account, which would trigger Account validation again
  rescue StandardError => e
    Rails.logger.error "Failed to log moderation violation: #{e.message}"
  end

  public

  # ==> Federated Username Display Methods

  # Returns the full federated identifier (@username@instance or @username@local)
  def federated_identifier
    if federated_id.present?
      # Already has a federated ID like "username@remote.instance"
      "@#{federated_id}"
    else
      # Local account - use local instance domain
      instance_domain = LibreverseInstance::Application.instance_domain
      "@#{username}@#{instance_domain}"
    end
  end

  # Returns just the username part without @ symbols
  def display_username
    username
  end

  # Returns the instance domain part
  def instance_domain
    if federated_id.present?
      # Extract domain from federated_id (format: username@domain)
      federated_id.split("@").last
    else
      # Local instance
      LibreverseInstance::Application.instance_domain
    end
  end

  # Check if this is a federated (remote) account
  def federated?
    federated_id.present?
  end

  # Check if this is a local account
  def local?
    !federated?
  end

  # Role-based authentication helpers (matching ActiveRecord Account model)
  def authenticated_user?
    !guest?
  end

  def effective_user?
    # For AccountSequel, check if not guest and exists in database
    !guest? && !new?
  end

  # Add has_role? method for Sequel model to work with Rolify
  def has_role?(role_name, resource = nil)
    # For AccountSequel, we can check roles directly through the database
    # This avoids the circular dependency issue
    return false if new?

    # Query the database directly to check for roles using Sequel's db connection
    role_query = db[:accounts_roles]
                 .join(:roles, id: :role_id)
                 .where(account_id: id)
                 .where(Sequel[:roles][:name] => role_name.to_s)

    # If resource is specified, also check resource_type and resource_id
    role_query = if resource
      role_query.where(
        Sequel[:roles][:resource_type] => resource.class.name,
        Sequel[:roles][:resource_id] => resource.id
      )
    else
      # For global roles, resource_type and resource_id should be null
      role_query.where(
        Sequel[:roles][:resource_type] => nil,
        Sequel[:roles][:resource_id] => nil
      )
    end

    role_query.count.positive?
  end

  # Keep the old role? method as an alias for backwards compatibility
  def role?(role_name)
    has_role?(role_name)
  end
end

# ActiveRecord bridge for associations
class Account < ApplicationRecord
  has_many :account_roles, dependent: :destroy
  has_many :roles, through: :account_roles
  rolify
  self.table_name = "accounts"

  # Include Federails ActorEntity for ActivityPub federation (only in non-test environments)
  # Also check if the federails_actors table exists to avoid migration issues
  unless Rails.env.test?
    begin
      if ActiveRecord::Base.connection.table_exists?(:federails_actors)
        include Federails::ActorEntity

        # Configure field names for federation
        acts_as_federails_actor username_field: :username,
                                name_field: :username,
                                profile_url_method: :profile_url
      end
    rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
      # Skip federails setup if database/table doesn't exist (e.g., during migrations)
    end
  end

  # Add ActiveRecord associations
  has_many :experiences, dependent: :destroy
  has_many :user_preferences, dependent: :destroy
  has_many :moderation_logs, dependent: :destroy

  # Content moderation validations
  validate :username_moderation

  # Callbacks for role assignment
  after_create :assign_default_role
  after_update :assign_default_role, if: :saved_change_to_guest?

  # Add any AR-specific logic or validations here if needed

  # Status helpers (matching Sequel model)
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

  # Role-based authentication helpers
  def authenticated_user?
    !guest?
  end

  def effective_user?
    authenticated_user? && !guest?
  end

  # Assign appropriate role based on guest status
  def assign_default_role
    if guest?
      add_role(:guest) unless has_role?(:guest)
    else
      add_role(:user) unless has_role?(:user)
      # Remove guest role if account is no longer a guest
      remove_role(:guest) if has_role?(:guest)
    end
  end

  def profile_url
    "https://#{LibreverseInstance::Application.instance_domain}/users/#{username}"
  end

  # Public method to ensure a federails actor exists for this account
  # Replaces the need to use send(:create_federails_actor)
  def ensure_federails_actor!
    return federails_actor if federails_actor.present?

    # Manually trigger actor creation by accessing the private method
    # This is the proper way to ensure actor creation
    send(:create_federails_actor)
    reload # Reload to get the newly created association
    federails_actor
  rescue StandardError => e
    Rails.logger.error "Failed to ensure federails actor for account #{id}: #{e.message}"
    raise e
  end

  private

  def username_moderation
    return if username.blank?

    return unless ModerationService.contains_inappropriate_content?(username)

      violations = ModerationService.get_violation_details(username)
      log_moderation_violation("username", username, violations)
      errors.add(:username, "contains inappropriate content and cannot be saved")
  end

  def log_moderation_violation(field, _content, violations)
    violations ||= []
    reason = if violations.empty?
      "content flagged by comprehensive moderation system"
    else
      violations.map { |v| "#{v[:type]}#{v[:details] ? " (#{v[:details].join(', ')})" : ''}" }.join("; ")
    end

    # Only log to Rails logger to avoid recursion since Account moderation
    # would trigger when creating ModerationLog records
    Rails.logger.warn "Moderation violation in #{self.class.name} #{field}: #{reason}"

    # NOTE: We don't log Account violations to database to avoid infinite recursion
    # since the ModerationLog belongs_to :account, which would trigger Account validation again
  rescue StandardError => e
    Rails.logger.error "Failed to log moderation violation: #{e.message}"
  end

  # ==> Federated Username Display Methods (matching Sequel model)

  # Returns the full federated identifier (@username@instance or @username@local)
  def federated_identifier
    if federated_id.present?
      # Already has a federated ID like "username@remote.instance"
      "@#{federated_id}"
    else
      # Local account - use local instance domain
      instance_domain = LibreverseInstance::Application.instance_domain
      "@#{username}@#{instance_domain}"
    end
  end

  # Returns just the username part without @ symbols
  def display_username
    username
  end

  # Returns the instance domain part
  def instance_domain
    if federated_id.present?
      # Extract domain from federated_id (format: username@domain)
      federated_id.split("@").last
    else
      # Local instance
      LibreverseInstance::Application.instance_domain
    end
  end

  # Check if this is a federated (remote) account
  def federated?
    federated_id.present?
  end

  # Check if this is a local account
  def local?
    !federated?
  end
end

# Ensure timestamps for accounts_roles join table (Sequel direct insert)
Sequel::Model(:accounts_roles).define_method(:before_create) do
  self[:created_at] ||= Time.zone.now if respond_to?(:created_at) && !self[:created_at]
  self[:updated_at] ||= Time.zone.now if respond_to?(:updated_at) && !self[:updated_at]
  super()
end
