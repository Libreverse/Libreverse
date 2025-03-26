class UserPreference < ApplicationRecord
  belongs_to :account

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
    # Truncate value if it's too long
    value = value.to_s.truncate(1000) if value.to_s.length > 1000

    # Only proceed if key is allowed
    return nil unless ALLOWED_KEYS.include?(key)

    preference = find_or_initialize_by(account_id: account_id, key: key)
    preference.value = value

    # Log the preference change
    if preference.new_record?
      Rails.logger.info "Creating new preference: account_id=#{account_id}, key=#{key}"
    else
      Rails.logger.info "Updating preference: account_id=#{account_id}, key=#{key}"
    end

    preference.save
    value
  end

  # Helper method to specifically set a dismissal preference
  def self.dismiss(account_id, key)
    # Only proceed if key is allowed
    return nil unless ALLOWED_KEYS.include?(key)

    Rails.logger.info "Dismissing: account_id=#{account_id}, key=#{key}"
    set(account_id, key, "dismissed")
  end

  # Helper method to check if something is dismissed
  def self.dismissed?(account_id, key)
    return false if account_id.nil?
    get(account_id, key) == "dismissed"
  end
end
