# frozen_string_literal: true

# Configure Premailer for CSS inlining in emails
Rails.application.configure do
  # Enable CSS inlining in all environments for consistent email rendering
  ActionMailer::Base.register_interceptor(Premailer::Rails::Hook)
end

# Configure Premailer options
Premailer::Rails.config.merge!(
  # === Basic Configuration ===
  input_encoding: "UTF-8",
  strategies: Rails.env.production? ? [ :filesystem ] : [ :network ], # Use filesystem in production, network in development
  generate_text_part: true, # Auto-generate text version
  adapter: :nokogiri_fast, # Use Nokogiri for HTML parsing (fast and reliable)
  timeout: 5, # Timeout for network requests

  # === CSS Processing Options ===
  remove_ids: false,                   # Keep IDs for email client compatibility
  remove_classes: false,               # Keep classes for Foundation compatibility
  preserve_styles: true,               # Keep style attributes
  drop_unmergeable_css_rules: true,    # Remove CSS that can't be inlined
  css_to_attributes: true,             # Only convert to attributes in production
  strip_css: false,                    # Keep CSS for debugging in development
  css_string_fallbacks: true,

  # === HTML Processing Options ===
  remove_comments: true,               # Remove HTML comments (like WhitespaceCompressor)
  strip_whitespace: true,              # Strip whitespace like HAML's ugly mode
  preserve_line_breaks: false,         # Remove unnecessary line breaks
  with_html_string: true,
  escape_url_attributes: true,         # Escape URLs properly for email clients

  # === URL Handling ===
  link_query_string: nil,              # Don't append query strings to links
  base_url: nil                        # Use relative URLs where possible
)
