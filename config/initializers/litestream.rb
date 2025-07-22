# frozen_string_literal: true

# Litestream Configuration for LibReverse
# This integrates Litestream with the centralized configuration system
# and requires specific environment variables to be set for security.

Rails.application.configure do
  # Require environment variables for Litestream configuration
  # Unlike other parts of this app, Litestream requires explicit ENV vars for security

  # Check for required environment variables
  required_env_vars = %w[
    LITESTREAM_REPLICA_BUCKET
    LITESTREAM_ACCESS_KEY_ID
    LITESTREAM_SECRET_ACCESS_KEY
  ]

  missing_vars = required_env_vars.select { |var| ENV[var].blank? }

  if missing_vars.any? && Rails.env.production?
    Rails.logger.fatal "CRITICAL: Litestream is required for production durability but missing environment variables: #{missing_vars.join(', ')}"
    raise "Production deployment failed: Litestream requires the following environment variables for database durability: #{missing_vars.join(', ')}"
  elsif missing_vars.any?
    Rails.logger.warn "Missing Litestream environment variables (#{missing_vars.join(', ')}). Litestream will be disabled."
  end

  # Configure Litestream only if all required environment variables are present
  if missing_vars.empty?
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

    Rails.logger.info "Litestream configured with bucket: #{ENV['LITESTREAM_REPLICA_BUCKET']}"
  else
    Rails.logger.info "Litestream disabled due to missing environment variables"
  end

  # Configure the default Litestream config path
  config.litestream.config_path = Rails.root.join("config/litestream.yml")
end
