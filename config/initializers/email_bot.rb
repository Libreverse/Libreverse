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
