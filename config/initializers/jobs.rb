# Jobs Configuration
# This file configures background job processing with Solid Queue

Rails.application.config.after_initialize do
  # Only set up recurring jobs in a web process to avoid duplicate scheduling
  next unless defined?(Rails::Server) || Rails.env.test?

  # Register recurring jobs from the recurring.yml configuration
  # Use empty hash as fallback if config_for returns nil
  recurring_config = Rails.application.config_for(:recurring) || {}

  # Load jobs for the current environment
  env_sym = Rails.env.to_sym
  if recurring_config.key?(env_sym) && recurring_config[env_sym].present?
    env_config = recurring_config[env_sym]

    env_config.each do |job_name, job_config|
      Rails.logger.info "Registering recurring job: #{job_name}"

      SolidQueue::RecurringExecution.register(
        job_name.to_s,
        job_class: job_config[:class],
        schedule: job_config[:schedule],
        queue: job_config[:queue] || "default",
        args: job_config[:args] || []
      )
    end

    Rails.logger.info "Finished registering #{env_config.size} recurring jobs for environment: #{Rails.env}"
  else
    Rails.logger.info "No recurring jobs configured for environment: #{Rails.env}"
  end
end
