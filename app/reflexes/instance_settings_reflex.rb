# frozen_string_literal: true

class InstanceSettingsReflex < ApplicationReflex
  before_reflex :ensure_admin

  def toggle_automoderation
    current_value = InstanceSetting.get("automoderation_enabled")
    new_value = current_value == "true" ? "false" : "true"

    InstanceSetting.set("automoderation_enabled", new_value, "Enable or disable content automoderation instance-wide")

    # Log the change
    Rails.logger.info "[Admin] User #{current_account.id} toggled instance automoderation to #{new_value == 'true' ? 'enabled' : 'disabled'}"
  end

  def toggle_eea_mode
    current_value = InstanceSetting.get("eea_mode_enabled")
    new_value = current_value == "true" ? "false" : "true"

    InstanceSetting.set("eea_mode_enabled", new_value, "Enable or disable EEA privacy mode instance-wide")

    # Log the change
    Rails.logger.info "[Admin] User #{current_account.id} toggled instance EEA mode to #{new_value == 'true' ? 'enabled' : 'disabled'}"
  end

  def toggle_force_ssl
    current_value = InstanceSetting.get("force_ssl")
    new_value = current_value == "true" ? "false" : "true"

    InstanceSetting.set("force_ssl", new_value, "Force all connections to use SSL/HTTPS")

    # Clear cached config to use new value
    LibreverseInstance::Application.reset_all_cached_config!

    # Log the change with environment context
    env_default = Rails.env.production? ? "enabled" : "disabled"
    Rails.logger.info "[Admin] User #{current_account.id} toggled force SSL to #{new_value == 'true' ? 'enabled' : 'disabled'} (environment default: #{env_default})"
  end

  def toggle_no_ssl
    current_value = InstanceSetting.get("no_ssl")
    new_value = current_value == "true" ? "false" : "true"

    InstanceSetting.set("no_ssl", new_value, "Disable SSL requirements entirely")

    # Clear cached config to use new value
    LibreverseInstance::Application.reset_all_cached_config!

    # Log the change
    Rails.logger.info "[Admin] User #{current_account.id} toggled no SSL to #{new_value == 'true' ? 'enabled' : 'disabled'}"
  end

  def update_rails_log_level(value)
    # Validate log level
    valid_levels = %w[debug info warn error fatal unknown]
    value = value.to_s.downcase.strip
    value = "info" unless valid_levels.include?(value)

    InstanceSetting.set("rails_log_level", value, "Rails application log level")

    # Clear cached config to use new value
    LibreverseInstance::Application.reset_all_cached_config!

    # Log the change
    Rails.logger.info "[Admin] User #{current_account.id} updated Rails log level to #{value}"
  end

  def update_allowed_hosts(value)
    # Clean up the value - remove extra spaces and empty entries
    value = value.to_s.strip
    hosts = value.split(",").map(&:strip).reject(&:empty?)
    cleaned_value = hosts.join(", ")

    InstanceSetting.set("allowed_hosts", cleaned_value, "Comma-separated list of allowed hostnames")

    # Clear cached config to use new value
    LibreverseInstance::Application.reset_all_cached_config!

    # Log the change
    Rails.logger.info "[Admin] User #{current_account.id} updated allowed hosts to: #{cleaned_value}"
  end

  def update_cors_origins(value)
    # Clean up the value - remove extra spaces and empty entries
    value = value.to_s.strip
    if value == "*"
      cleaned_value = "*"
    else
      origins = value.split(",").map(&:strip).reject(&:empty?)
      cleaned_value = origins.join(", ")
    end

    InstanceSetting.set("cors_origins", cleaned_value, "Comma-separated list of allowed CORS origins")

    # Clear cached config to use new value
    LibreverseInstance::Application.reset_all_cached_config!

    # Log the change with environment context
    env_default = Rails.env.development? || Rails.env.test? ? "*" : "domain-based"
    Rails.logger.info "[Admin] User #{current_account.id} updated CORS origins to: #{cleaned_value} (environment default: #{env_default})"
  end

  def update_port(value)
    # Validate port number
    port = value.to_i
    port = 3000 if port < 1 || port > 65_535

    InstanceSetting.set("port", port.to_s, "Application server port number")

    # Clear cached config to use new value
    LibreverseInstance::Application.reset_all_cached_config!

    # Log the change
    Rails.logger.info "[Admin] User #{current_account.id} updated application port to #{port}"
  end

  def update_admin_email(value)
    # Validate email format
    value = value.to_s.strip
    unless value.match?(/\A[^@\s]+@[^@\s]+\z/)
      # If invalid, use a sensible default
      domain = LibreverseInstance::Application.instance_domain.gsub(/:\d+$/, "")
      value = "admin@#{domain}"
    end

    InstanceSetting.set("admin_email", value, "Primary admin contact email address")

    # Clear cached config to use new value
    LibreverseInstance::Application.reset_all_cached_config!

    # Log the change
    Rails.logger.info "[Admin] User #{current_account.id} updated admin email to: #{value}"
  end

  private

  def ensure_admin
    return if current_account&.admin?

    Rails.logger.warn "[Security] Non-admin user #{current_account&.id || 'anonymous'} attempted to access admin instance settings"
    throw :abort
  end

  # Helper method to safely set instance settings with error handling
  def safe_set_setting(key, value, description)
      InstanceSetting.set(key, value, description)
      true
  rescue StandardError => e
      Rails.logger.error "[Admin] Failed to update setting #{key}: #{e.message}"
      false
  end
end
