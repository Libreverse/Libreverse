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

    # this option set is from the default readme of htmlcompressor
    config.middleware.use HtmlCompressor::Rack,
                          enabled: true,
                          remove_spaces_inside_tags: true,
                          remove_multi_spaces: false,
                          remove_comments: true,
                          remove_intertag_spaces: true,
                          remove_quotes: false,
                          compress_css: false,
                          compress_javascript: false,
                          simple_doctype: false,
                          remove_script_attributes: false,
                          remove_style_attributes: false,
                          remove_link_attributes: false,
                          remove_form_attributes: false,
                          remove_input_attributes: false,
                          remove_javascript_protocol: false,
                          remove_http_protocol: false,
                          remove_https_protocol: false,
                          preserve_line_breaks: false,
                          simple_boolean_attributes: false,
                          compress_js_templates: false
  end
end
