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

  # Force skipping the Rack proxy layer so we avoid HTTP/1.1 downgrade / 426 issues.
  # Mirrors the JSON config (config/vite.json -> development.skipProxy = true)
  # but we also export the env var early so any pre-initialization hooks see it.
  ENV["VITE_RUBY_SKIP_PROXY"] = "true"

  # Apply explicit configuration so the middleware proxy is reliable.
  ViteRuby.configure do |config|
    config.mode = :development
    config.public_output_dir = "vite-dev"
  # Prefer IPv4 loopback to avoid IPv6-only (::1) binding mismatches
  config.host = "127.0.0.1"
    config.port = 3001
    config.https = false
    config.auto_build = true
    # Also set via Ruby API for good measure
    config.dev_server_connect_timeout = 2.5 if config.respond_to?(:dev_server_connect_timeout=)
    # We're using Bun for JS package management in this project
    config.package_manager = :bun if config.respond_to?(:package_manager=)
    # Some newer vite_ruby versions expose a skip_proxy flag (guard in case of older gem)
    config.skip_proxy = true if config.respond_to?(:skip_proxy=)
  end
end
