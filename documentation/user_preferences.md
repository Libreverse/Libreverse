# User Preferences

## Overview

The User Preferences system in Libreverse allows users to customize their experience, save their settings, and manage notification preferences. The system provides a flexible and persistent way to store user-specific settings across sessions.

## Preference Types

### Dismissible Notifications

- **Tutorial Prompts**: First-time user guides that can be dismissed
- **Feature Announcements**: Updates about new platform features
- **Tips & Hints**: Contextual usage tips that users can opt out of

### Interface Preferences

- **Theme Settings**: Light/dark mode and color preferences
- **Layout Options**: Content density and organization preferences
- **Accessibility Settings**: Font size, contrast, and display adjustments

### Notification Preferences

- **Email Notifications**: Control which emails are received
- **In-app Notifications**: Toggle visibility of different notification types
- **Frequency Settings**: Control how often notifications are delivered

## Managing Preferences

### User Interface

Preferences can be managed through:

- **Settings Panel**: Accessible from the dashboard
- **Contextual Controls**: Directly from the feature where preferences apply
- **Dismissal Actions**: "Don't show again" options on notifications

### Persistence

- Preferences are stored persistently in the database
- Changes take effect immediately across devices
- Preferences are maintained between sessions

## Technical Implementation

### Data Model

The `UserPreference` model is the core of the preference system:

```ruby
# Key fields
user_id     # Integer: Associated user (or nil for anonymous)
key         # String: Preference identifier (e.g., "dashboard-tutorial")
value       # String/JSON: The stored preference value
updated_at  # DateTime: When the preference was last changed
```

### API Access

Preferences can be accessed programmatically via the XML-RPC API:

- `preferences.isDismissed`: Check if a specific notification has been dismissed
- `preferences.dismiss`: Mark a notification as dismissed

### Implementation Patterns

The preference system follows these patterns:

- **Lazy Loading**: Preferences are loaded only when needed
- **Default Values**: System provides sensible defaults when preferences aren't set
- **Scoped Storage**: Preferences are organized by feature area for maintainability

## Using the Preference System

### Checking Preferences

To check if a user has dismissed a specific feature:

```ruby
# In controllers or views
UserPreference.dismissed?(current_account&.id, "feature-key")
```

### Setting Preferences

To update a preference value:

```ruby
# Mark feature as dismissed
UserPreference.dismiss(current_account&.id, "feature-key")
```

### Preference Keys

Common preference keys include:

- `dashboard-tutorial`: First-time dashboard walkthrough
- `experience-creation-guide`: Experience creation tutorial
- `search-tips`: Search feature usage tips
- `theme-preference`: Interface theme setting
- `notification-email`: Email notification settings

## Best Practices

### For Developers

- Use consistent naming conventions for preference keys
- Group related preferences by prefix
- Provide sensible defaults for all preferences
- Clean up obsolete preferences during major updates

### For Feature Design

- Make all tutorials and guides dismissible
- Respect user preferences consistently across the platform
- Allow granular control over notification types
- Provide easy ways to reset preferences to defaults

## Future Enhancements

Planned improvements to the preference system include:

- Profile-based preference presets
- Time-based preference resets (e.g., re-show tips after 3 months)
- Preference import/export functionality
- Advanced preference analytics to improve feature design
