# frozen_string_literal: true

class UserPreference < ApplicationRecord
  # belongs_to :account # Removed: Account is now a Sequel model

  # Encrypt the value field since it may contain sensitive user preferences
  # Use deterministic encryption since we need to query these values
  encrypts :value, deterministic: true, downcase: false

  validates :key, presence: true, uniqueness: { scope: :account_id }
  validates :key, length: { maximum: 50 } # Limit key length
  validates :value, length: { maximum: 1000 } # Limit value size

  # Whitelist of allowed preference keys
  ALLOWED_KEYS = %w[
    dashboard-tutorial
    search-tutorial
    welcome-message
    feature-announcement
    theme-selection
    sidebar_expanded
    sidebar_hovered
    drawer_expanded_main
    locale
  ].freeze

  validate :key_must_be_allowed

  # Custom validation to ensure key is in whitelist
  def key_must_be_allowed
    return if ALLOWED_KEYS.include?(key)

    errors.add(:key, "is not an allowed preference key")
  end

  # Get a preference value for a specific account and key
  def self.get(account_id, key)
    find_by(account_id: account_id, key: key)&.value
  end

  # Set a preference value for a specific account and key
  def self.set(account_id, key, value)
    key_string = key.to_s # Ensure key is a string for comparison
    # Truncate value if it's too long
    value = value.to_s.truncate(1000) if value.to_s.length > 1000

    # Only proceed if key is allowed
    return nil unless ALLOWED_KEYS.include?(key_string)

    # Normalize the value to 't' or 'f' for boolean-like values
    normalized_value = normalize_value(value)

    preference = find_or_initialize_by(account_id: account_id, key: key_string)
    preference.value = normalized_value

    # Log the preference change
    if preference.new_record?
      Rails.logger.info "Creating new preference: account_id=#{account_id}, key=#{key}, value=#{normalized_value}"
    else
      Rails.logger.info "Updating preference: account_id=#{account_id}, key=#{key}, value=#{normalized_value}"
    end

    begin
      preference.save! # Use save! to raise an error on validation failure
      normalized_value
    rescue StandardError => e
      Rails.logger.error "[UserPreference] Validation failed for account #{account_id}, key '#{key}': #{e.message}"
      nil # Return nil on error
    end
  end

  # Helper method to specifically set a dismissal preference
  def self.dismiss(account_id, key)
    # Only proceed if key is allowed
    return nil unless ALLOWED_KEYS.include?(key)

    Rails.logger.info "Dismissing: account_id=#{account_id}, key=#{key}"
    set(account_id, key, "t") # Use 't' consistently for dismissed state
  end

  # Helper method to check if something is dismissed
  def self.dismissed?(account_id, key)
    return false if account_id.nil?

    get(account_id, key) == "t" # Check for 't' consistently
  end

  # Manual bridge to Sequel Account model
  def sequel_account
    AccountSequel[account_id]
  end

  # Normalize value to consistent format
  def self.normalize_value(value)
    case value.to_s.downcase
    when "true", "t", "1", "yes", "dismissed"
      "t"
    when "false", "f", "0", "no"
      "f"
    else
      value.to_s # Keep other values as is
    end
  end
end
