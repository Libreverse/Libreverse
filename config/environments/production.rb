require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in ENV["RAILS_MASTER_KEY"], config/master.key, or an environment
  # key such as config/credentials/production.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from `public/`, relying on NGINX/Apache to do so instead.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Active Storage
  config.active_storage.service = :local

  # Action Cable Configuration
  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  # config.action_cable.allowed_request_origins = [ "https://your-production-domain.com", /https:\/\/your-production-domain.*/ ]

  # SSL Enforcement
  config.assume_ssl = true
  config.force_ssl = true

  # Logger Configuration
  config.logger =
    ActiveSupport::Logger
    .new($stdout)
    .tap { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Log level
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL") { "info" }

  # Cache Store Configuration
  config.cache_store = :solid_cache_store, { database_url: ENV["DATABASE_URL"] }

  # Active Job Queue Adapter Configuration
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }
  # config.active_job.queue_name_prefix = "libreverse_instance_production"

  # I18n Fallbacks
  config.i18n.fallbacks = true

  # Deprecation Notices
  config.active_support.deprecation = :notify
  config.active_support.report_deprecations = false

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Host Authorization
  config.hosts = %w[libreverse.geor.me libreverse.dev localhost:3000]
  # Skip DNS rebinding protection for the default health check endpoint.
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  # Secure session configuration
  config.session_store :active_record_store,
                       key: "_libreverse_session",
                       secure: true,
                       httponly: true,
                       expire_after: 2.hours,
                       same_site: :strict

  # Enforce SameSite=Strict for all cookies
  config.action_dispatch.cookies_same_site_protection = :strict

  # Add secure defaults for new cookies
  config.action_dispatch.cookies_serializer = :json
  config.action_dispatch.use_authenticated_cookie_encryption = true
  config.action_dispatch.signed_cookie_digest = "SHA256"

  # Action Cable Logging
  ActionCable.server.config.logger = Logger.new(nil)
end
