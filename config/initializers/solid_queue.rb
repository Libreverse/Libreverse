# Configure Solid Queue recurring jobs
Rails.application.config.after_initialize do
  # Only set up recurring jobs in a web process to avoid duplicate scheduling
  next unless defined?(Rails::Server) || Rails.env.test?

  # Skip this for now until SolidQueue setup is complete
  Rails.logger.info "Skipping SolidQueue recurring job setup temporarily"
end
