# MailHog Integration - Quick Start Guide

## Overview

MailHog has been successfully integrated into LibreVerse for development email testing. This allows you to:

- Catch all outgoing emails during development
- View emails in a web interface
- Test email templates and functionality
- Prevent accidental email sending to real addresses

## Quick Start

### 1. Start Development Server with MailHog

```bash
# Start all development services including MailHog
foreman start
```

This will start:

- Rails server on `http://localhost:3000`
- Vite dev server for assets
- MailHog on ports 1025 (SMTP) and 8025 (Web UI)

### 2. View Emails

Open MailHog web interface: <http://localhost:8025>

### 3. Test Email Sending

Any emails sent by your Rails application will be caught by MailHog instead of being delivered to real email addresses.

## Configuration Details

### Environment-Specific Settings

**Development (`config/environments/development.rb`):**

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: 'localhost',
  port: 1025,
  domain: 'localhost'
}
```

**Test (`config/environments/test.rb`):**

```ruby
config.action_mailer.delivery_method = :test
```

**Production (`config/environments/production.rb`):**

````ruby
config.action_mailer.delivery_method = :smtp
# Uses environment variables for SMTP configuration
```ruby

### Procfile

The `Procfile` includes MailHog for development:

```text
web: bundle exec iodine
vite: bin/vite dev
mailhog: mailhog
````

## Foundation for Emails Integration

Emails use Foundation for Emails templates with:

- Responsive design that works across all email clients
- Both HTML and text versions
- Professional styling with inline CSS

## Testing Workflow

1. **Start Services**: `foreman start`
2. **Develop Features**: Create or modify email functionality
3. **Trigger Emails**: Use your application to send emails
4. **View Results**: Check <http://localhost:8025> to see sent emails
5. **Iterate**: Modify templates and test again

## Production Deployment

In production, MailHog is not included. The system uses:

- Environment variables for SMTP configuration
- Proper email delivery to real addresses
- Professional email layouts with Foundation for Emails

## Troubleshooting

### MailHog Not Starting

- Check if port 1025 is available: `lsof -i :1025`
- Ensure MailHog is installed: `which mailhog`
- Install with: `brew install mailhog` (macOS)

### Emails Not Appearing

- Verify MailHog is running on port 1025
- Check Rails logs for email delivery attempts
- Confirm development environment is using correct SMTP settings

### CSS Not Loading

- Ensure Vite dev server is running
- Check that `/vite/emails.css` is accessible
- Verify Foundation for Emails build completed successfully

## Related Documentation

- [Foundation for Emails Integration](foundation-for-emails.md)
- [Email Configuration Guide](email-configuration.md)
- [MailHog Official Documentation](https://github.com/mailhog/MailHog)
