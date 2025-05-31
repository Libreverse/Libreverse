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
      @eea_mode_enabled = InstanceSetting.get_with_fallback("eea_mode_enabled", "EEA_MODE", "true") == "true"
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
