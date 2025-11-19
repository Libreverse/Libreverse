module Admin
  class InstanceSettingsController < ApplicationController
    include EnhancedSpamProtection

    # Enhanced spam protection for admin settings
    invisible_captcha only: %i[create update],
                      honeypot: nil, # Use random honeypot
                      on_spam: :handle_comprehensive_spam_detection,
                      on_timestamp_spam: :handle_timestamp_spam_detection,
                      timestamp_threshold: 2, # Even stricter for admin actions
                      timestamp_enabled: true

    before_action :require_admin
    before_action :check_enhanced_spam_protection, only: %i[create update]
    before_action :set_instance_setting, only: %i[show edit update destroy]

  def index
    # Preload all required settings in a single query to avoid N+1 queries
    required_keys = %w[
      automoderation_enabled
      eea_mode_enabled
      force_ssl
      rails_log_level
      allowed_hosts
      cors_origins
      admin_email
      no_ssl
      port
    ]

@instance_settings = InstanceSetting.where(key: required_keys).order(:key)
settings_hash      = @instance_settings.pluck(:key, :value).to_h

    # Helper method to get setting with fallback using preloaded hash
    get_setting_with_fallback = lambda do |key, env_var = nil, default = nil|
      value = settings_hash[key]
      return value if value.present?

      if env_var.present?
        env_value = ENV[env_var]
        return env_value if env_value.present?
      end

      default
    end

    # Provide current values for toggle switches
    @automoderation_enabled = ActiveModel::Type::Boolean.new.cast(
      get_setting_with_fallback.call("automoderation_enabled", nil, "true")
    )
    @eea_mode_enabled = get_setting_with_fallback.call("eea_mode_enabled", nil, "true") == "true"
    @force_ssl = get_setting_with_fallback.call("force_ssl", nil, Rails.env.production? ? "true" : "false") == "true"

    # Get current values for text inputs
    rails_log_default = if Rails.env.development?
      "debug"
    else
      Rails.env.test? ? "error" : "info"
    end
    @rails_log_level = get_setting_with_fallback.call("rails_log_level", "RAILS_LOG_LEVEL", rails_log_default)
    @allowed_hosts = get_setting_with_fallback.call("allowed_hosts", "ALLOWED_HOSTS", "localhost")
    cors_default = Rails.env.development? || Rails.env.test? ? "*" : "localhost"
    @cors_origins = get_setting_with_fallback.call("cors_origins", "CORS_ORIGINS", cors_default)
    @admin_email = get_setting_with_fallback.call("admin_email", "ADMIN_EMAIL", "admin@localhost")

    # Advanced settings (loaded on demand)
    @no_ssl = get_setting_with_fallback.call("no_ssl", "NO_SSL", "false") == "true"
    @port = get_setting_with_fallback.call("port", "PORT", "3000")
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
