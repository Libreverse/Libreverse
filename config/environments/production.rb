# frozen_string_literal: true

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

  # Always serve precompiled static files from `public/`.
  config.public_file_server.enabled = true

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

  # SSL Enforcement (forced via env var)
  # Must provide FORCE_SSL with explicit truthy/falsey value, otherwise boot aborts.
  ssl_flag = ENV.fetch("FORCE_SSL") # raises if missing
  ssl_enabled = %w[true 1 yes on].include?(ssl_flag.to_s.downcase)

  config.assume_ssl = ssl_enabled
  config.force_ssl  = ssl_enabled

  # Logger Configuration
  config.logger =
    ActiveSupport::Logger
    .new($stdout)
    .tap { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Log level (must be provided via env var)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL")

  # Cache Store Configuration
  config.cache_store = :solid_cache_store

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

  # Host Authorization - controlled via ALLOWED_HOSTS environment variable
  allowed_hosts_env = ENV.fetch("ALLOWED_HOSTS")
  allowed_hosts = allowed_hosts_env.split(/[\s,]+/).reject(&:blank?)

  # Replace the default array entirely so we don't accumulate duplicates
  config.hosts.clear
  allowed_hosts.each { |host| config.hosts << host }

  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  # --- Use CookieStore (Permanent Change) ---
  config.session_store :cookie_store,
                       key: "_libreverse_session",
                       secure: true, # Keep security settings
                       httponly: true,
                       expire_after: 2.hours,
                       same_site: :strict # Keep security settings
  # ----------------------------------------

  # Action Cable Logging
  ActionCable.server.config.logger = Logger.new(nil)
end
