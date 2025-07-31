# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.session_store :cookie_store,
                       key: "_libreverse_session",
                       expire_after: 2.hours, # Match previous setting
                       domain: nil # Allow both localhost and ::1 in development
# ------------------------------------------
# === Configure ActionCable URL for consistency ===
# Use default port for development (3000)
config.action_cable.url = "ws://localhost:3000/cable"
config.action_cable.allowed_request_origins = [
  "http://localhost:3000",
  "http://127.0.0.1:3000",
  "http://[::1]:3000"
]
# ===============================================

# Default URL options should also match
config.action_controller.default_url_options = { host: "localhost", port: 3000 }

  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.enable_reloading = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Disable browser caching in development
  config.public_file_server.enabled = false

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Use Solid Cache for caching with SQLite
  config.cache_store = :solid_cache_store, { database: :cache }
  config.solid_cache.connects_to = { database: { writing: :cache, reading: :cache } }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true

  # Raises error for missing translations.
  config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = true

  # Noisy Action Cable
  config.action_cable.log_tags = [ :action_cable ]
  config.action_cable.logger = ActiveSupport::Logger.new($stdout)
  config.action_cable.logger.level = Logger::ERROR

  # Use Solid Queue for Active Job
  config.active_job.queue_adapter = :solid_queue

  # Configure Solid Queue for TiDB compatibility
  config.solid_queue.connects_to = { database: { writing: :primary } }
  config.solid_queue.use_skip_locked = false

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

  config.file_watcher = ActiveSupport::EventedFileUpdateChecker
end
