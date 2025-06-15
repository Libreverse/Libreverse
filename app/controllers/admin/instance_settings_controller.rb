# frozen_string_literal: true

module Admin
  class InstanceSettingsController < ApplicationController
    # Enhanced spam protection for admin settings
    invisible_captcha only: %i[create update],
                      honeypot: nil, # Use random honeypot
                      on_spam: :handle_comprehensive_spam_detection,
                      on_timestamp_spam: :handle_timestamp_spam_detection,
                      timestamp_threshold: 2, # Even stricter for admin actions
                      timestamp_enabled: true

    before_action :require_admin
    before_action :set_instance_setting, only: %i[show edit update destroy]

    def index
      @instance_settings = InstanceSetting.all.order(:key)

      # Provide current values for toggle switches
      @automoderation_enabled = InstanceSetting.get_with_fallback("automoderation_enabled", nil, "true") == "true"
      @eea_mode_enabled = InstanceSetting.get_with_fallback("eea_mode_enabled", nil, "true") == "true"
      @force_ssl = InstanceSetting.get_with_fallback("force_ssl", nil, Rails.env.production? ? "true" : "false") == "true"

      # Get current values for text inputs
      rails_log_default = if Rails.env.development?
        "debug"
      else
        Rails.env.test? ? "error" : "info"
      end
      @rails_log_level = InstanceSetting.get_with_fallback("rails_log_level", "RAILS_LOG_LEVEL", rails_log_default)
      @allowed_hosts = InstanceSetting.get_with_fallback("allowed_hosts", "ALLOWED_HOSTS", "localhost")
      cors_default = Rails.env.development? || Rails.env.test? ? "*" : "localhost"
      @cors_origins = InstanceSetting.get_with_fallback("cors_origins", "CORS_ORIGINS", cors_default)
      @admin_email = InstanceSetting.get_with_fallback("admin_email", "ADMIN_EMAIL", "admin@localhost")

      # Advanced settings (loaded on demand)
      @no_ssl = InstanceSetting.get_with_fallback("no_ssl", "NO_SSL", "false") == "true"
      @port = InstanceSetting.get_with_fallback("port", "PORT", "3000")
    end

    def show
    end

    def new
      @instance_setting = InstanceSetting.new
    end

    def edit
    end

    def create
      @instance_setting = InstanceSetting.new(instance_setting_params)

      if @instance_setting.save
        redirect_to admin_instance_settings_path, notice: "Instance setting was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @instance_setting.update(instance_setting_params)
        redirect_to admin_instance_settings_path, notice: "Instance setting was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @instance_setting.destroy
      redirect_to admin_instance_settings_path, notice: "Instance setting was successfully deleted."
    end

    private

    def require_admin
      redirect_to root_path, alert: "Access denied." unless current_account&.admin?
    end

    def set_instance_setting
      @instance_setting = InstanceSetting.find(params[:id])
    end

    def instance_setting_params
      params.require(:instance_setting).permit(:key, :value, :description)
    end
  end
end
