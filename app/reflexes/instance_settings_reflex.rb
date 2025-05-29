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

  private

  def ensure_admin
    return if current_account&.admin?

      Rails.logger.warn "[Security] Non-admin user #{current_account&.id || 'anonymous'} attempted to access admin instance settings"
      throw :abort
  end
end
