# frozen_string_literal: true

# Configure HAML options for Rails templates
# Note: remove_whitespace works in coordination with WhitespaceCompressor middleware
# HAML handles template-level whitespace removal, middleware handles remaining optimization
Haml::Template.options[:remove_whitespace] = true
Haml::Template.options[:format] = :html5
Haml::Template.options[:attr_wrapper] = '"'
Haml::Template.options[:escape_html] = true
