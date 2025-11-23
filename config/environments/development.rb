# frozen_string_literal: true
# shareable_constant_value: literal

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

  # We are messing with how people generally work in dev for performance here:
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

  # Use Solid Cache for caching with SQLite; coder is set via initializer
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
  config.active_record.verbose_query_logs = false

  # Disable SQL logging for ActiveRecord
  config.active_record.logger = nil

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = false

  # Raises error for missing translations.
  config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = true

  # Noisy Action Cable
  config.action_cable.log_tags = [ :action_cable ]
  config.action_cable.logger = ActiveSupport::Logger.new($stdout)
  config.action_cable.logger.level = Logger::ERROR

  # Use Delayed Job for Active Job
  config.active_job.queue_adapter = :delayed_job

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

  # Ensure HTTP/1.1 in development: clear any Alt-Svc hints from responses
  # so that clients don't attempt HTTP/2/3 upgrades against localhost.
  remove_alt_svc = Class.new do
    def initialize(app) = (@app = app)

    def call(env)
      status, headers, body = @app.call(env)
      headers.delete("Alt-Svc")
      [ status, headers, body ]
    end
  end
  config.middleware.insert_before 0, remove_alt_svc
end
