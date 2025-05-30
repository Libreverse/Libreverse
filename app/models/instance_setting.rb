# frozen_string_literal: true

class InstanceSetting < ApplicationRecord
  # Encrypt sensitive values
  encrypts :value, deterministic: true, downcase: false

  validates :key, presence: true, uniqueness: true
  validates :key, length: { maximum: 100 }
  validates :value, length: { maximum: 10_000 }
  validates :description, length: { maximum: 500 }

  # Allowed setting keys for security
  ALLOWED_KEYS = %w[
    instance_name
    instance_description
    instance_domain
    canonical_host
    admin_email
    admin_signal_url
    admin_twitter_handle
    security_contact_email
    security_contact_signal
    security_contact_twitter
    privacy_policy_url
    acknowledgements_url
    preferred_languages
    no_bots_mode
    automoderation_enabled
    eea_mode_enabled
  ].freeze

  validate :key_must_be_allowed

  # Get a setting value by key
  def self.get(key)
    find_by(key: key)&.value
  end

  # Set a setting value by key
  def self.set(key, value, description = nil)
    return nil unless ALLOWED_KEYS.include?(key.to_s)

    setting = find_or_initialize_by(key: key.to_s)
    setting.value = value.to_s
    setting.description = description if description.present?

    if setting.save
      setting.value
    else
      Rails.logger.error "[InstanceSetting] Failed to save setting #{key}: #{setting.errors.full_messages.join(', ')}"
      nil
    end
  end

  # Get setting with fallback to environment variable or default
  def self.get_with_fallback(key, env_var = nil, default = nil)
    # First try database
    value = get(key)
    return value if value.present?

    # Then try environment variable
    if env_var.present?
      env_value = ENV[env_var]
      return env_value if env_value.present?
    end

    # Finally return default
    default
  end

  # Initialize default settings
  def self.initialize_defaults!
    defaults = {
      "instance_name" => "Libreverse Instance",
      "instance_description" => "An instance of the Metaverse, but open-source",
      "instance_domain" => ENV["INSTANCE_DOMAIN"] || "localhost:3000",
      "admin_email" => ENV["ADMIN_EMAIL"] || "admin@example.com",
      "admin_signal_url" => ENV["ADMIN_SIGNAL_URL"] || "",
      "admin_twitter_handle" => ENV["ADMIN_TWITTER_HANDLE"] || "",
      "security_contact_email" => ENV["SECURITY_CONTACT_EMAIL"] || "",
      "security_contact_signal" => ENV["SECURITY_CONTACT_SIGNAL"] || "",
      "security_contact_twitter" => ENV["SECURITY_CONTACT_TWITTER"] || "",
      "privacy_policy_url" => "/privacy",
      "acknowledgements_url" => "/security",
      "preferred_languages" => "en",
      "no_bots_mode" => "false",
      "automoderation_enabled" => "true",
      "eea_mode_enabled" => "true"
    }

    defaults.each do |key, default_value|
      next if exists?(key: key) # Don't overwrite existing settings

      set(key, default_value, "Default setting for #{key.humanize}")
    end
  end

  private

  def key_must_be_allowed
    return if ALLOWED_KEYS.include?(key)

    errors.add(:key, "is not an allowed setting key")
  end
end
