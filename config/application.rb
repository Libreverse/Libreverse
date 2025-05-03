# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_view/railtie"
require "active_job/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Load custom middleware
require_relative "../lib/middleware/whitespace_compressor"
require_relative "../lib/middleware/zstd"

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

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # For some reason I don't really understand, it only works if defined here.
    # I would put it in an initializer, but it causes content encoding issues.

    # Strange as it may seem this is the order that gets the html minifier
    # to run before the deflater and brotli because middlewares are,
    # unintuitively, run as a stack from the bottom up.
    config.middleware.use Rack::Deflater,
                          sync: false

    config.middleware.use Rack::Brotli,
                          quality: 11,
                          deflater: {
                            lgwin: 22,
                            lgblock: 0,
                            mode: :text
                          },
                          sync: false

    # Zstandard compression middleware
    if defined?(Rack::Zstd)
      # Use default options or customize levels as needed
      config.middleware.use Rack::Zstd,
                            level: 3,
                            sync: false
    end

    # Add WhitespaceCompressor middleware to minify HTML before compression
    config.middleware.use WhitespaceCompressor
  end
end
