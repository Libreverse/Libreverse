# frozen_string_literal: true
# shareable_constant_value: literal

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Dev runs behind an HTTPS reverse-proxy (Caddy). Treat requests as SSL so
  # secure cookies (e.g., profiler/session) and generated URLs stay scheme-consistent.
  config.assume_ssl = true

  config.session_store :cookie_store,
                       key: "_libreverse_session",
                       expire_after: 2.hours,
                       domain: :all,
                       same_site: :none,
                       secure: true

  # Configure ActionCable URL for consistency 
  # Use default port for development (3000)
  config.action_cable.url = "wss://localhost:3000/cable"
  config.action_cable.allowed_request_origins = [
    "https://localhost:3000",
    "https://127.0.0.1:3000",
    "https://[::1]:3000",
    "https://localhost:5173",
    "https://127.0.0.1:5173",
    "https://[::1]:5173",
    "file://"
  ]

  # Default URL options should also match
  config.action_controller.default_url_options = { protocol: "https", host: "localhost", port: 3000 }

  # Settings specified here will take precedence over those in config/application.rb.
  config.enable_reloading = true
  config.eager_load = true

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Disable browser caching in development
  config.public_file_server.enabled = false

  # Store uploaded files in the database using active_storage_db
  config.active_storage.service = :db

  # Silence all deprecation warnings
  config.active_support.deprecation = :silence
  config.active_support.report_deprecations = false

  # Disable disallowed deprecation behavior
  config.active_support.disallowed_deprecation = :silence

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = false

  # Disable SQL logging for ActiveRecord
  config.active_record.logger = nil

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = false

  # Raises error for missing translations.
  config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  config.action_view.annotate_rendered_view_with_filenames = false

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = true

  # Noisy Action Cable
  config.action_cable.log_tags = [ :action_cable ]
  config.action_cable.logger = ActiveSupport::Logger.new($stdout)
  config.action_cable.logger.level = Logger::ERROR

  # Use Sidekiq for Active Job
  config.active_job.queue_adapter = :sidekiq

  # Email configuration for development (MailHog)
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: "localhost",
    port: 1025,
    domain: "localhost"
  }
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
  config.action_mailer.perform_caching = false
  config.action_mailer.raise_delivery_errors = true
end
