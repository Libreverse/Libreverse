require_relative "boot"
require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Configuration for the application, engines, and railties goes here.
#
# These settings can be overridden in specific environments using the files
# in config/environments, which are processed later.
#
# config.time_zone = "Central Time (US & Canada)"
# config.eager_load_paths << Rails.root.join("extras")

module LibreverseInstance
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Use fibers for concurrency stonks
    config.active_support.isolation_level = :fiber

    # Configure security headers
    config.action_dispatch.default_headers = {
      # Prevent clickjacking
      "X-Frame-Options" => "SAMEORIGIN",
      # Prevents browsers from MIME-sniffing
      "X-Content-Type-Options" => "nosniff",
      # XSS protection
      "X-XSS-Protection" => "1; mode=block",
      # Referrer policy
      "Referrer-Policy" => "strict-origin-when-cross-origin",
      # Cross-origin policies
      "Cross-Origin-Opener-Policy" => "same-origin",
      "Cross-Origin-Resource-Policy" => "same-origin"
    }

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])
  end
end
