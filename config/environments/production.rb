# frozen_string_literal: true

require "active_support/core_ext/integer/time"
require "re2"

Rails.application.configure do
  # Prepare the ingress controller used to receive mail
  # config.action_mailbox.ingress = :relay

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
  config.public_file_server.enabled = false

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

  # SSL Enforcement (using centralized configuration)
  ssl_enabled = LibreverseInstance::Application.force_ssl?

  config.assume_ssl = ssl_enabled
  config.force_ssl  = ssl_enabled

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Log level (using centralized configuration)
  config.log_level = LibreverseInstance::Application.rails_log_level

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

  # Host Authorization - using centralized configuration
  allowed_hosts = LibreverseInstance::Application.allowed_hosts

  # Always allow localhost and 127.0.0.1
  %w[localhost 127.0.0.1].each do |local_host|
    allowed_hosts << local_host unless allowed_hosts.include?(local_host)
  end

  # Replace the default array entirely so we don't accumulate duplicates
  config.hosts.clear
  allowed_hosts.each { |host| config.hosts << host }

  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  # --- Use CookieStore (Permanent Change) ---
  config.session_store :cookie_store,
                       key: "_libreverse_session",
                       secure: config.force_ssl,
                       httponly: true,
                       expire_after: 2.hours,
                       same_site: :strict # Keep security settings
  # ----------------------------------------

  # Email configuration for production
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV.fetch("SMTP_ADDRESS") { "localhost" },
    port: ENV.fetch("SMTP_PORT") { "587" }.to_i,
    domain: ENV.fetch("SMTP_DOMAIN") { LibreverseInstance.instance_domain },
    user_name: ENV["SMTP_USERNAME"],
    password: ENV["SMTP_PASSWORD"],
    authentication: ENV.fetch("SMTP_AUTHENTICATION") { "plain" },
    enable_starttls_auto: ENV.fetch("SMTP_ENABLE_STARTTLS_AUTO") { "true" } == "true",
    openssl_verify_mode: ENV.fetch("SMTP_OPENSSL_VERIFY_MODE") { "peer" }
  }
  config.action_mailer.default_url_options = {
    host: ENV.fetch("MAILER_HOST") { LibreverseInstance.instance_domain },
    protocol: "https"
  }
  config.action_mailer.perform_caching = false
  config.action_mailer.raise_delivery_errors = false
end
