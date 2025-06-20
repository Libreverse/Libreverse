# Email CSS Inlining System

This document describes the comprehensive CSS inlining system for emails in Libreverse, which works seamlessly across development and production environments.

## Overview

The email CSS inlining system provides:

- **Development**: Real-time CSS fetching from Vite dev server (including CSS extracted from JavaScript)
- **Production**: Efficient CSS inlining from compiled assets
- **Testing**: Fallback mechanisms and consistent behavior
- **Foundation for Emails**: Integration with email framework
- **Premailer**: Advanced CSS inlining and optimization

## Architecture

### Core Components

1. **EmailHelper** (`app/helpers/email_helper.rb`)

    - Primary interface for CSS inlining
    - Environment-aware CSS processing
    - Foundation for Emails integration

2. **ViteCssFetcher** (`app/services/vite_css_fetcher.rb`)

    - Fetches CSS from Vite dev server in development
    - Extracts CSS from JavaScript responses
    - Handles network errors gracefully

3. **Premailer Configuration** (`config/initializers/premailer.rb`)
    - Configures CSS inlining behavior
    - Optimizes for email clients
    - Handles media queries and responsive design

## Usage

### Basic Email CSS Inlining

```ruby
class MyMailer < ApplicationMailer
  include EmailHelper

  def my_email(user)
    @user = user
    @inlined_css = inline_email_css("~/stylesheets/emails.scss")

    mail(to: @user.email, subject: "Hello!")
  end
end
```

### Direct Stylesheet Inlining

```ruby
# For specific stylesheets
@newsletter_css = inline_vite_stylesheet("newsletter.scss")
@base_css = inline_email_css("~/stylesheets/emails.scss")
```

### Email Template

```erb
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <style type="text/css">
    <%= @inlined_css %>
  </style>
</head>
<body>
  <!-- Your email content -->
</body>
</html>
```

## Environment-Specific Behavior

### Development Environment

1. **Vite Dev Server Integration**

    - Fetches CSS from `http://localhost:5173`
    - Handles SCSS compilation in real-time
    - Extracts CSS from JavaScript modules

2. **Fallback Mechanisms**

    - Falls back to compiled CSS if dev server unavailable
    - Uses Foundation for Emails CDN as final fallback

3. **Live Reloading**
    - Changes to SCSS files are reflected immediately
    - No need to restart Rails server

### Production Environment

1. **Asset Pipeline Integration**

    - Uses precompiled CSS from Vite build
    - Reads from `public/assets/` directory
    - Optimized for performance

2. **Caching**
    - CSS content is cached for efficiency
    - Manifest-based asset resolution

### Test Environment

1. **Predictable Behavior**
    - Uses test-specific CSS fallbacks
    - Mocks external dependencies
    - Consistent across test runs

## File Structure

```text
app/
├── helpers/
│   └── email_helper.rb              # Main CSS inlining helper
├── mailers/
│   ├── application_mailer.rb        # Base mailer with EmailHelper
│   └── welcome_mailer.rb           # Example mailer implementation
├── services/
│   └── vite_css_fetcher.rb         # Vite dev server CSS fetcher
├── stylesheets/
│   ├── emails.scss                 # Base email styles
│   ├── foundation-emails.scss      # Foundation for Emails
│   └── newsletter.scss             # Newsletter-specific styles
└── views/
    ├── layouts/
    │   └── mailer.html.erb         # Email layout template
    └── welcome_mailer/
        ├── welcome_email.html.erb   # Welcome email template
        └── newsletter.html.erb      # Newsletter template

config/
└── initializers/
    └── premailer.rb                # Premailer configuration

scripts/
└── test_email_css.rb              # Testing and validation script

test/
├── helpers/
│   └── email_helper_test.rb        # EmailHelper tests
└── services/
    └── vite_css_fetcher_test.rb    # ViteCssFetcher tests
```

## CSS Processing Flow

### Development Flow

1. `EmailHelper.inline_email_css()` called
2. `ViteCssFetcher.fetch_css()` requests CSS from Vite dev server
3. If response contains JavaScript, CSS is extracted using regex
4. CSS is processed through Premailer for inlining
5. Inlined CSS returned to email template

### Production Flow

1. `EmailHelper.inline_email_css()` called
2. CSS file path resolved through Rails asset helpers
3. Compiled CSS read from filesystem
4. CSS processed through Premailer for inlining
5. Inlined CSS returned to email template

## Configuration

### Vite Configuration

Ensure your `vite.config.js` includes email stylesheets:

```javascript
// vite.config.js
export default {
    // ... other config
    build: {
        rollupOptions: {
            input: {
                application: "./app/javascript/application.js",
                emails: "./app/stylesheets/emails.scss",
            },
        },
    },
};
```

### Premailer Configuration

The Premailer initializer configures CSS inlining behavior:

```ruby
# config/initializers/premailer.rb
Premailer::Rails.config.merge!(
  remove_ids: false,
  remove_comments: true,
  preserve_styles: true,
  generate_text_part: false
)
```

## Testing

### Running Tests

```bash
# Test the complete system
rails runner scripts/test_email_css.rb

# Run unit tests
rails test test/helpers/email_helper_test.rb
rails test test/services/vite_css_fetcher_test.rb
```

### Manual Testing

```bash
# Start development servers
bin/rails server
bin/vite dev

# Send test email in Rails console
rails console
> WelcomeMailer.welcome_email(User.first).deliver_now
```

## Troubleshooting

### Common Issues

1. **Vite Dev Server Not Running**

    - Start with `bin/vite dev`
    - Check port configuration in `config/vite.json`

2. **CSS Not Loading in Development**

    - Verify Vite dev server is accessible at `http://localhost:5173`
    - Check browser network tab for 404s

3. **Missing CSS in Production**

    - Run `bin/vite build` to compile assets
    - Verify compiled CSS exists in `public/assets/`

4. **Email Client Compatibility**
    - Test with Email on Acid or Litmus
    - Adjust Premailer configuration as needed

### Debug Mode

Enable debug logging in `EmailHelper`:

```ruby
# In email_helper.rb
Rails.logger.debug "[EmailHelper] CSS content: #{css_content.length} characters"
```

## Best Practices

1. **Email-Specific Stylesheets**

    - Keep email CSS separate from web CSS
    - Use Foundation for Emails framework
    - Test across email clients

2. **Performance Optimization**

    - Minimize CSS file size
    - Use efficient selectors
    - Optimize images and assets

3. **Responsive Design**

    - Use media queries for responsive emails
    - Test on mobile devices
    - Consider dark mode support

4. **Development Workflow**
    - Keep Vite dev server running during email development
    - Use browser developer tools to inspect inlined CSS
    - Test emails in multiple clients early and often

## Security Considerations

- CSS content is sanitized through Premailer
- External asset fetching is restricted to development
- Production uses only locally compiled assets
- Email templates should be treated as trusted content

## Performance Notes

- Development: CSS fetched on each email render (suitable for development)
- Production: CSS read from filesystem with potential caching
- Large CSS files may impact email generation time
- Consider CSS optimization for high-volume email sending
