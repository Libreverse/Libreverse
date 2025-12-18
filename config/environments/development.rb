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

# ------------------------------------------
# === Configure ActionCable URL for consistency ===
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
# ===============================================

# Default URL options should also match
config.action_controller.default_url_options = { protocol: "https", host: "localhost", port: 3000 }

  # Settings specified here will take precedence over those in config/application.rb.

  # TruffleRuby JIT benefits significantly from eager loading - all code is loaded
  # and parsed upfront, allowing the JIT to compile hot methods during warmup.
  # This trades slower boot time for faster request handling.
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

  # Cache store inherits from application.rb (Redis/DragonflyDB)
  # Uncomment below to use memory store for isolated development:
  # config.cache_store = :memory_store

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
  config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

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

  # ---------------------------------------------------------------------------
  # TruffleRuby compatibility + TiDB transient retry
  # ---------------------------------------------------------------------------

  # web-console 4.2.1 can raise when mapping ActiveRecord exceptions on TruffleRuby
  # (e.g., NoMethodError: undefined method `bindings` for ActiveRecord::StatementInvalid).
  # Disable it so the app can continue rendering even when the DB is temporarily unhealthy.
  config.middleware.delete(WebConsole::Middleware) if defined?(WebConsole::Middleware)

  tidb_transient_retry = Class.new do
    MAX_RETRIES = 3

    def initialize(app)
      @app = app
    end

    def call(env)
      attempts = 0

      begin
        @app.call(env)
      rescue ActiveRecord::StatementInvalid => e
        raise unless retryable_tidb?(e.cause)

        attempts += 1
        raise if attempts > MAX_RETRIES

        ActiveRecord::Base.clear_active_connections! if defined?(ActiveRecord::Base)
        sleep(backoff(attempts))
        retry
      rescue ActiveRecord::ConnectionNotEstablished => e
        attempts += 1
        raise if attempts > MAX_RETRIES

        ActiveRecord::Base.clear_active_connections! if defined?(ActiveRecord::Base)
        sleep(backoff(attempts))
        retry
      rescue StandardError => e
        # Don't swallow unrelated application errors.
        raise unless retryable_connection_error?(e)

        attempts += 1
        raise if attempts > MAX_RETRIES

        ActiveRecord::Base.clear_active_connections! if defined?(ActiveRecord::Base)
        sleep(backoff(attempts))
        retry
      end
    end

    private

    def retryable_tidb?(cause)
      return false unless cause

      msg = cause.message.to_s
      msg.include?("Region is unavailable") ||
        msg.include?("trilogy_query_recv") ||
        msg.include?("trilogy_connect")
    end

    def retryable_connection_error?(error)
      klass = error.class.name
      return true if klass == "Trilogy::ConnectionError"

      msg = error.message.to_s
      msg.include?("trilogy_connect") || msg.include?("unable to connect")
    end

    def backoff(attempt)
      [ 0.1 * (2**(attempt - 1)), 1.0 ].min
    end
  end

  config.middleware.insert_before 0, tidb_transient_retry
end
