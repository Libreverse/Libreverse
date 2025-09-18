# frozen_string_literal: true

# Ensure Vite Ruby uses sane defaults in development and doesn't give up
# too quickly when connecting to the Vite dev server.
if Rails.env.development?
  # Safety net: environment variable wins, but if it's missing or set too low,
  # bump it to something reasonable (seconds).
  begin
    timeout = Float(ENV["VITE_RUBY_DEV_SERVER_CONNECT_TIMEOUT"] || 0)
  rescue ArgumentError, TypeError
    timeout = 0
  end
  ENV["VITE_RUBY_DEV_SERVER_CONNECT_TIMEOUT"] = "2.5" if timeout <= 0.1

  # Apply explicit configuration so the middleware proxy is reliable.
  ViteRuby.configure do |config|
    config.mode = :development
    config.public_output_dir = "vite-dev"
  # Prefer IPv4 loopback to avoid IPv6-only (::1) binding mismatches
  config.host = "127.0.0.1"
    config.port = 3001
    config.https = false
    config.auto_build = false
    # Also set via Ruby API for good measure
    if config.respond_to?(:dev_server_connect_timeout=)
      config.dev_server_connect_timeout = 2.5
    end
    # We're using Bun for JS package management in this project
    config.package_manager = :bun if config.respond_to?(:package_manager=)
  end
end
