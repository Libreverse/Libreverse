# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# Action Mailbox configuration that integrates with Libreverse's InstanceSetting system
Rails.application.configure do
  # Configure Action Mailbox IMAP settings using InstanceSetting values with intelligent defaults
  config.action_mailbox.imap = {
    host: -> { LibreverseInstance.email_bot_mail_host },
    port: 993, # Standard IMAPS port
    ssl: true, # Always use SSL for security
    username: -> { LibreverseInstance.email_bot_username },
    password: -> { LibreverseInstance.email_bot_password }
  }

  # Only configure SMTP for production - development and test have their own configs
  if Rails.env.production?
    # Configure Action Mailer SMTP settings for outgoing emails with intelligent defaults
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: -> { LibreverseInstance.email_bot_mail_host },
      port: 587, # Standard SMTP submission port
      user_name: -> { LibreverseInstance.email_bot_username },
      password: -> { LibreverseInstance.email_bot_password },
      authentication: :plain, # Most common authentication method
      enable_starttls_auto: true # Always use TLS for security
    }
  end

  # Set default from address for email bot responses
  config.action_mailer.default_options = {
    from: -> { LibreverseInstance.email_bot_address }
  }

  # Only enable email bot if configured
  config.action_mailbox.ingress = LibreverseInstance.email_bot_enabled? ? :imap : nil
end

# Configure Inky for Foundation for Emails templates
require "inky"

ActionView::Template.register_template_handler(:inky, Inky::Rails::TemplateHandler)

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
