# Email Configuration Guide

This document describes the email configuration setup in LibreVerse across different environments.

## Overview

LibreVerse uses environment-specific email configurations:

- **Development**: MailHog for local email testing
- **Test**: Test delivery method (emails stored in memory)
- **Production**: SMTP with configurable settings

## Development Environment

### MailHog Setup

MailHog is included in the Procfile and will run automatically when you start the development server.

**Starting the development server with MailHog:**

```bash
foreman start
```

This will start:

- Rails server on port 3000
- Vite dev server for assets
- MailHog on port 8025 (web UI) and 1025 (SMTP)

**MailHog Web Interface:**

- URL: <http://localhost:8025>
- View all emails sent during development
- No email delivery to real addresses

**Configuration** (`config/environments/development.rb`):

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: 'localhost',
  port: 1025,
  domain: 'localhost'
}
config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
```

## Test Environment

**Configuration** (`config/environments/test.rb`):

```ruby
config.action_mailer.delivery_method = :test
config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
```

Emails are stored in `ActionMailer::Base.deliveries` array for testing.

## Production Environment

**Configuration** (`config/environments/production.rb`):
Production uses environment variables for SMTP configuration:

### Required Environment Variables

- `SMTP_ADDRESS` - SMTP server address (default: localhost)
- `SMTP_PORT` - SMTP server port (default: 587)
- `SMTP_DOMAIN` - SMTP domain (default: instance domain)
- `SMTP_USERNAME` - SMTP authentication username
- `SMTP_PASSWORD` - SMTP authentication password

### Optional Environment Variables

- `SMTP_AUTHENTICATION` - Authentication method (default: plain)
- `SMTP_ENABLE_STARTTLS_AUTO` - Enable STARTTLS (default: true)
- `SMTP_OPENSSL_VERIFY_MODE` - SSL verification mode (default: peer)
- `MAILER_HOST` - Host for email links (default: instance domain)

### Example Production Setup

```bash
# SMTP Configuration
export SMTP_ADDRESS="smtp.mailgun.org"
export SMTP_PORT="587"
export SMTP_DOMAIN="yourdomain.com"
export SMTP_USERNAME="postmaster@yourdomain.com"
export SMTP_PASSWORD="your-smtp-password"

# Optional
export SMTP_AUTHENTICATION="plain"
export SMTP_ENABLE_STARTTLS_AUTO="true"
export MAILER_HOST="yourdomain.com"
```

## Email Bot Integration

The email bot configuration in `config/initializers/email_bot.rb` is environment-aware:

- **Development/Test**: Uses environment-specific configurations
- **Production**: Uses LibreVerse instance settings for SMTP

### Instance Settings

The following can be configured via the admin interface:

- `email_bot_enabled` - Enable/disable email bot
- `email_bot_address` - Bot email address
- `email_bot_mail_host` - IMAP/SMTP server
- `email_bot_username` - Authentication username
- `email_bot_password` - Authentication password

## Foundation for Emails

Email templates use Foundation for Emails:

- Templates: `app/views/*_mailer/*.html.inky`
- Compiled CSS: `/vite/emails.css`
- Responsive, cross-client compatible

## Testing Emails

### Development Testing

1. Start the server: `foreman start`
2. Trigger email sending in your application
3. View emails at <http://localhost:8025>
4. Test responsive design and content

### Production Testing

1. Configure SMTP environment variables
2. Send test emails
3. Monitor delivery logs
4. Test with various email clients

### Email Template Testing

```ruby
# In Rails console or test
mailer = YourMailer.your_method(params)
puts mailer.body.to_s  # View HTML output
```

## Common SMTP Providers

### Mailgun

```bash
SMTP_ADDRESS="smtp.mailgun.org"
SMTP_PORT="587"
SMTP_USERNAME="postmaster@your-domain.mailgun.org"
```

### SendGrid

```bash
SMTP_ADDRESS="smtp.sendgrid.net"
SMTP_PORT="587"
SMTP_USERNAME="apikey"
SMTP_PASSWORD="your-sendgrid-api-key"
```

### AWS SES

```bash
SMTP_ADDRESS="email-smtp.us-east-1.amazonaws.com"
SMTP_PORT="587"
SMTP_USERNAME="your-ses-username"
SMTP_PASSWORD="your-ses-password"
```

## Troubleshooting

### MailHog Not Starting

- Check if port 1025 is available: `lsof -i :1025`
- Ensure MailHog is installed: `which mailhog`
- Check Procfile syntax

### Production Email Issues

- Verify SMTP credentials
- Check firewall/security group settings
- Test SMTP connectivity: `telnet smtp-server 587`
- Review application logs for delivery errors

### Template Rendering Issues

- Verify Inky template syntax
- Check Foundation for Emails CSS inclusion
- Test template compilation in console

## Security Considerations

- Always use TLS/STARTTLS in production
- Store SMTP credentials securely (environment variables)
- Use strong passwords for email accounts
- Monitor for email abuse/spam
- Implement rate limiting for email sending
