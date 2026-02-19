# frozen_string_literal: true
# shareable_constant_value: literal

HighVoltage.configure do |config|
  # We define explicit static page routes in config/routes.rb to preserve
  # existing helper names (/terms, /privacy, /cookies).
  config.routes = false
  config.content_path = "pages/"
end
