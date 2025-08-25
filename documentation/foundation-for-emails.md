# Foundation for Emails Integration

This document describes the Foundation for Emails integration in LibreVerse, which provides responsive HTML email templates.

## Overview

Foundation for Emails is a framework for creating responsive HTML emails that work across all email clients. We've integrated it with our Rails application to provide modern, accessible email templates.

## Setup Components

### 1. Gems Added

- `inky-rb` - Ruby implementation of the Inky template language
- `foundation_emails` - Foundation for Emails stylesheets and components

### 2. Template Handler

A custom template handler at `config/initializers/inky_template_handler.rb` processes `.html.inky` templates:

- Converts Inky markup to HTML tables compatible with email clients
- Integrates with Rails' Action View system
- Supports ERB for dynamic content

### 3. Asset Pipeline Integration

Foundation for Emails styles are included via Vite:

- Entry point: `app/javascript/emails.js`
- Stylesheet: `app/javascript/stylesheets/emails.scss`
- Compiled CSS served at `/vite/emails.css`

### 4. Mailer Layout

The base email layout (`app/views/layouts/mailer.html.erb`) includes:

- Foundation for Emails CSS
- Meta tags for responsive email rendering
- Proper DOCTYPE for email clients

## Usage

### Creating Email Templates

1. Create templates with `.html.inky` extension in mailer views
2. Use Foundation for Emails components:

```inky
<container>
  <wrapper>
    <row>
      <columns>
        <h1>Email Title</h1>
        <p>Email content here</p>
        <button href="https://example.com">Call to Action</button>
      </columns>
    </row>
  </wrapper>
</container>
```

### Available Components

- `<container>` - Main email wrapper
- `<wrapper>` - Section wrapper with background
- `<row>` and `<columns>` - Grid system
- `<button>` - Call-to-action buttons
- `<spacer>` - Vertical spacing
- `<center>` - Center content
- `<menu>` - Horizontal navigation

### CSS Classes

Foundation for Emails provides utility classes for:

- Text alignment: `.text-center`, `.text-left`, `.text-right`
- Colors: `.primary-color`, `.secondary-color`
- Spacing: `.small-padding`, `.large-padding`
- Typography: `.h1`, `.h2`, `.subheader`

## Example Implementation

See `app/views/search_results_mailer/search_results.html.inky` for a complete example of:

- Grid layout with responsive columns
- Dynamic content with ERB
- Button components
- Conditional rendering
- Semantic HTML structure

## Testing

To test email templates:

1. Run `rails server` to start the application
2. Email templates are compiled automatically when accessed
3. CSS is served at `/vite/emails.css`
4. Use email preview tools or send test emails

## Benefits

- **Cross-client compatibility**: Works in all major email clients
- **Responsive design**: Adapts to mobile and desktop
- **Maintainable**: Clean Inky syntax instead of complex HTML tables
- **Rails integration**: Seamless ERB template support
- **Asset pipeline**: Proper CSS handling with cache busting

## Troubleshooting

- Ensure `bundle install` has been run to install gems
- Check that Vite build includes email assets
- Verify template handler is loaded in Rails initializers
- Test Inky compilation with simple templates first

## Resources

- [Foundation for Emails Documentation](https://get.foundation/emails.html)
- [Inky Template Language](https://get.foundation/emails/docs/inky.html)
- [Email Client Testing](https://www.emailonacid.com/)
