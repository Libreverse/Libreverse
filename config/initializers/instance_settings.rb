# frozen_string_literal: true

# Instance Settings Initializer
# This initializer sets up default instance configuration values

Rails.application.config.after_initialize do
  # Only initialize defaults if we're in a Rails server context
  # Skip during asset precompilation, migrations, tests, etc.
  next unless defined?(Rails::Server)

  begin
    # Check if the table exists before trying to use it
    next unless ActiveRecord::Base.connection.table_exists?("instance_settings")

    # Only initialize if no settings exist yet to prevent duplicates
    if InstanceSetting.count.zero?
      InstanceSetting.initialize_defaults!
      Rails.logger.info "Instance settings initialized successfully"
    else
      Rails.logger.debug "Instance settings already exist, skipping initialization"
    end
  rescue StandardError => e
    Rails.logger.error "Failed to initialize instance settings: #{e.message}"
    # Don't raise in production to avoid breaking the app
    raise e unless Rails.env.production?
  end
end
