# frozen_string_literal: true

# Litestream Configuration for LibReverse
# This integrates Litestream with the centralized configuration system.
# Litestream is now optional and can be enabled/disabled through admin settings.

# Check if Litestream is enabled in settings (defaults to false for new installations)
def litestream_enabled?
  # Check if we have instance settings configured
  return false unless defined?(InstanceSetting)

  begin
    InstanceSetting.get("litestream_enabled") == "true"
  rescue StandardError
    # If settings aren't available yet (during migrations, etc.), default to false
    false
  end
end

Rails.application.configure do
  # Check for environment variables for Litestream configuration
  required_env_vars = %w[
    LITESTREAM_REPLICA_BUCKET
    LITESTREAM_ACCESS_KEY_ID
    LITESTREAM_SECRET_ACCESS_KEY
  ]

  missing_vars = required_env_vars.select { |var| ENV[var].blank? }

  # Only configure Litestream if it's enabled in settings AND all environment variables are present
  if litestream_enabled? && missing_vars.empty?
    # Replica configuration using required environment variables
    config.litestream.replica_bucket = ENV["LITESTREAM_REPLICA_BUCKET"]
    config.litestream.replica_key_id = ENV["LITESTREAM_ACCESS_KEY_ID"]
    config.litestream.replica_access_key = ENV["LITESTREAM_SECRET_ACCESS_KEY"]

    # Optional configuration with sensible defaults
    config.litestream.replica_region = ENV.fetch("LITESTREAM_REPLICA_REGION") { "us-east-1" }
    config.litestream.replica_endpoint = ENV["LITESTREAM_REPLICA_ENDPOINT"] if ENV["LITESTREAM_REPLICA_ENDPOINT"].present?

    # Configure the Litestream dashboard for admin integration
    config.litestream.base_controller_class = "Admin::BaseController"

    # Dashboard authentication (optional - will fall back to base controller auth)
    if Rails.env.production?
      config.litestream.username = Rails.application.credentials.dig(:litestream, :username)
      config.litestream.password = Rails.application.credentials.dig(:litestream, :password)
    end

    Rails.logger.info "Litestream configured and enabled with bucket: #{ENV['LITESTREAM_REPLICA_BUCKET']}"
  elsif !litestream_enabled?
    Rails.logger.info "Litestream disabled via admin settings"
  elsif missing_vars.any?
      Rails.logger.warn "Litestream enabled in settings but missing environment variables: #{missing_vars.join(', ')}"
  end

  # Configure the default Litestream config path
  config.litestream.config_path = Rails.root.join("config/litestream.yml")
end
