# frozen_string_literal: true

# Instance Settings Initializer
# This initializer sets up default instance configuration values

Rails.application.config.after_initialize do
  # Only initialize defaults if we're in a Rails server context
  # This prevents initialization during asset precompilation, migrations, etc.
  next unless defined?(Rails::Server) || Rails.env.test?

  begin
    # Initialize default instance settings
    InstanceSetting.initialize_defaults!
    Rails.logger.info "Instance settings initialized successfully"
  rescue StandardError => e
    Rails.logger.error "Failed to initialize instance settings: #{e.message}"
    # Don't raise in production to avoid breaking the app
    raise e unless Rails.env.production?
  end
end
