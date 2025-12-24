# frozen_string_literal: true
# shareable_constant_value: literal

require "temple/generators/array_buffer"

# Configure Slim options for Rails templates
Slim::Engine.set_options(
  format: :xhtml,
  attr_quote: '"',
  sort_attrs: false,
  pretty: false,
  streaming: false,
  disable_escape: false,
  use_html_safe: true,
  disable_capture: true,
  hyphen_underscore_attrs: true,
  js_wrapper: nil,
  generator: Temple::Generators::ArrayBuffer
)
