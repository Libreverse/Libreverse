# Libreverse Email Automation

This directory contains scripts and tools for automating email interactions with the Libreverse email system.

## Overview

Libreverse includes an email bot system that allows users to:

- Search for experiences via email
- Request downloadable experience files via email

The system accepts emails at two addresses:

- `search@your-domain.com` - for searching experiences
- `experiences@your-domain.com` - for requesting downloadable files

## Files

### `email_automation_script.rb`

Main automation script that can be run standalone or integrated with Rails. Provides:

- Automated space search emails
- Automated meditation experience requests
- Custom search and experience request functionality
- CLI interface for easy usage

### `email_bot_demo.rb`

Interactive demo script that shows how the email system works and provides examples.

### `../lib/tasks/email_bot.rake`

Rails tasks for email automation that work within the Rails environment.

## Quick Start

### Method 1: Rails Tasks (Recommended)

```bash
# Test both space search and meditation request
rails email_bot:both

# Search for specific content
rails email_bot:search['machine learning']

# Request specific experience
rails email_bot:experience['Meditation and Mindfulness Space']

# Check email bot status
rails email_bot:status
```

### Method 2: Standalone Ruby Script

```bash
# Run both automated emails
ruby scripts/email_automation_script.rb auto

# Custom search
ruby scripts/email_automation_script.rb search "space exploration"

# Custom experience request
ruby scripts/email_automation_script.rb experience "Meditation and Mindfulness Space"

# Show help
ruby scripts/email_automation_script.rb help
```

### Method 3: Interactive Demo

```bash
ruby scripts/email_bot_demo.rb
```

## Email Formats

### Search Email Format

**To:** `search@your-domain.com`
**Subject:** Your search query
**Body:**

```text
your search terms

--federated: false
--limit: 20
--format: links
```

**Options:**

- `--federated: true/false` - Search across federated instances
- `--limit: number` - Maximum results (1-100)
- `--format: links/attachment` - Response format

### Experience Request Format

**To:** `experiences@your-domain.com`
**Subject:** Experience title
**Body:**

```text
Experience Title Here

Optional message requesting the experience
```

**Note:** Only experiences marked as "offline available" can be requested.

## Configuration

### Environment Variables

For the standalone script:

```bash
export SMTP_HOST=your-smtp-server.com
export SMTP_PORT=587
export SMTP_USERNAME=your-username
export SMTP_PASSWORD=your-password
export FROM_EMAIL=your-bot@example.com
export LIBREVERSE_DOMAIN=your-libreverse-domain.com
```

### Rails Configuration

The Rails tasks use the existing ActionMailbox configuration and LibreverseInstance settings.

## Examples

### Example 1: Search for Space Content

```bash
# Using Rails task
rails email_bot:search['space exploration']

# Using standalone script
ruby scripts/email_automation_script.rb search "space exploration"
```

This sends an email like:

```text
From: automation@your-domain.com
To: search@your-domain.com
Subject: space exploration

space exploration

--federated: false
--limit: 10
--format: links
```

### Example 2: Request Meditation Experience

```bash
# Using Rails task
rails email_bot:experience['Meditation and Mindfulness Space']

# Using standalone script
ruby scripts/email_automation_script.rb experience "Meditation and Mindfulness Space"
```

This sends an email like:

```text
From: automation@your-domain.com
To: experiences@your-domain.com
Subject: Meditation and Mindfulness Space

Meditation and Mindfulness Space

---
Automated experience request
Please send the offline version of this experience.
```

## Troubleshooting

### Email Bot Not Working

1. Check if email bot is enabled:

    ```bash
    rails email_bot:status
    ```

2. Verify ActionMailbox is configured in your Rails app

3. Check that example experiences exist:

    ```bash
    rails runner "ExampleExperiencesService.new.add_examples"
    ```

### No Email Responses

1. Check your email delivery configuration
2. Monitor Rails logs for processing messages
3. Verify SMTP settings if using standalone script

### Experience Not Found

1. Ensure the experience exists and is approved
2. Check that it's marked as "offline available"
3. Use exact title matching

## Advanced Usage

### Custom Email Processing

You can create custom emails by understanding the system:

```ruby
# In Rails console
raw_email = <<~EMAIL
  From: test@example.com
  To: search@your-domain.com
  Subject: custom search

  machine learning tutorials

  --federated: true
  --limit: 50
  --format: attachment
EMAIL

ActionMailbox::InboundEmail.create_and_extract_message_id!(raw_email)
```

### Integration with External Systems

The `LibreverseEmailBot` class can be integrated into external applications:

```ruby
require_relative 'scripts/email_automation_script'

bot = LibreverseEmailBot.new(
  smtp_host: 'your-smtp.com',
  smtp_username: 'username',
  smtp_password: 'password',
  from_email: 'bot@example.com',
  instance_domain: 'your-libreverse.com'
)

bot.send_custom_search('AI tutorials')
bot.send_custom_experience_request('VR Experience')
```

## Security Notes

- The email bot only searches approved experiences
- Email processing is queued and rate-limited
- All emails are logged for monitoring
- Only experiences marked as offline-available can be requested

## Support

For issues or questions about the email automation system:

1. Check the Rails logs for error messages
2. Verify your email configuration
3. Use `rails email_bot:status` to check system status
4. Refer to the main Libreverse documentation
