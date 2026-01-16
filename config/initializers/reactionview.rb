# typed: strict
# frozen_string_literal: true
# shareable_constant_value: literal

ReActionView.configure do |config|
  # Intercept .html.erb templates and process them with `Herb::Engine` for enhanced features
  config.intercept_erb = true

  # Enable debug mode in development (adds debug attributes to HTML) (we don't use this enough to justify the overhead)
  config.debug_mode = false
end
