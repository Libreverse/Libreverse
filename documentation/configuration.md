# Instance Configuration Management

This document describes the centralized configuration system for LibReverse, which allows you to manage application settings through the database while maintaining environment variable fallbacks.

## Overview

LibReverse uses a hybrid configuration approach that prioritizes database-stored settings while maintaining compatibility with environment variables. This provides flexibility for different deployment scenarios and makes configuration changes possible without server restarts.

## Configuration Priority

The system follows this priority order:

1. **Database Setting** (via `InstanceSetting` model) - Highest priority
2. **Environment Variable** - Fallback if database setting doesn't exist
3. **Default Value** - Used if neither database nor environment variable is set

## Available Settings

### Core Application Settings

| Setting          | Database Key      | Environment Variable | Auto-Default                                 | Description                                            |
| ---------------- | ----------------- | -------------------- | -------------------------------------------- | ------------------------------------------------------ |
| Instance Domain  | `instance_domain` | `INSTANCE_DOMAIN`    | Smart detection in production                | Primary domain for this instance                       |
| Admin Email      | `admin_email`     | `ADMIN_EMAIL`        | `admin@[domain]` in production               | Primary admin contact email                            |
| Rails Log Level  | `rails_log_level` | `RAILS_LOG_LEVEL`    | `debug` (dev), `error` (test), `info` (prod) | Application logging level                              |
| Allowed Hosts    | `allowed_hosts`   | `ALLOWED_HOSTS`      | `localhost`                                  | Comma-separated list of allowed hostnames              |
| Application Port | `port`            | `PORT`               | `3000`                                       | Port number for the application server (fixed at 3000) |

### Security & SSL Settings

| Setting          | Database Key       | Environment Variable | Auto-Default                              | Description                                          |
| ---------------- | ------------------ | -------------------- | ----------------------------------------- | ---------------------------------------------------- |
| Force SSL        | `force_ssl`        | _(removed)_          | `true` in production, `false` in dev/test | Redirect all HTTP requests to HTTPS                  |
| Disable SSL      | `no_ssl`           | _(removed)_          | `false`                                   | Disable SSL requirements entirely                    |
| EEA Privacy Mode | `eea_mode_enabled` | _(removed)_          | `true`                                    | Enhanced privacy protections for European compliance |

### Network & CORS Settings

| Setting      | Database Key   | Environment Variable | Auto-Default                                | Description                                  |
| ------------ | -------------- | -------------------- | ------------------------------------------- | -------------------------------------------- |
| CORS Origins | `cors_origins` | `CORS_ORIGINS`       | `*` in dev/test, domain-based in production | Comma-separated list of allowed CORS origins |

### Reverse Proxy Auto-Detection

LibReverse automatically detects when running behind a reverse proxy on known platforms and adjusts static file serving accordingly:

- **Heroku**: Detected via `DYNO` environment variable
- **Railway**: Detected via `RAILWAY_ENVIRONMENT` environment variable  
- **Render**: Detected via `RENDER` environment variable
- **Fly.io**: Detected via `FLY_APP_NAME` environment variable

When a reverse proxy is detected, Iodine disables static file serving to avoid conflicts with the proxy's static file handling.

**Header-based Detection**: HTTP headers like `X-Forwarded-For` are only available during individual requests, not at boot time. If you need header-based proxy detection, implement it in a Rack middleware that can access `request.env`.

## Environment-Aware Defaults

The system automatically adjusts certain settings based on the Rails environment:

### Development & Test Environments

- **Instance Domain**: `localhost:3000` (dev), `localhost` (test)
- **Admin Email**: `admin@localhost`
- **Rails Log Level**: `debug` (dev), `error` (test)
- **Force SSL**: Disabled (to allow localhost development)
- **CORS Origins**: Set to `*` (allow all origins for development flexibility)
- **Port**: 3000 (standard Rails development port)

### Production Environment

- **Instance Domain**: Auto-detected from hosting platform environment variables
- **Admin Email**: `admin@[detected-domain]`
- **Rails Log Level**: `info` (balanced performance/troubleshooting)
- **Force SSL**: Enabled (security best practice)
- **CORS Origins**: Set to `https://[domain],http://[domain]` based on instance domain
- **Port**: 3000 (consistent across environments)

## Admin Interface

### Accessing Settings

Navigate to `/admin/instance_settings` in your LibReverse admin panel to manage these settings through a web interface.

### Features

- **Instance Identity**: Domain and admin email configuration
- **Security & Compliance**: EEA mode and automoderation toggles
- **Application Configuration**: SSL, logging, networking, and host settings
- **Advanced Settings**: Collapsible section for rarely-used settings (port, no-SSL mode)
- **Auto-save**: Changes are saved automatically with debouncing
- **Smart Defaults**: Environment-aware defaults with helpful hints
- **Validation**: Input validation and error handling
- **Audit Trail**: All changes are logged with admin user information

### UI Organization

The admin interface is organized into logical sections:

- **Essential Settings**: Always visible, commonly adjusted
- **Advanced Settings**: Collapsible section for edge cases and auto-determined settings

## Programmatic Access

### Reading Configuration

```ruby
# Access through the Application class (recommended)
LibreverseInstance::Application.instance_domain
LibreverseInstance::Application.rails_log_level
LibreverseInstance::Application.allowed_hosts     # Returns array
LibreverseInstance::Application.force_ssl?        # Returns boolean
LibreverseInstance::Application.cors_origins      # Returns array
LibreverseInstance::Application.port              # Returns integer

# Direct database access (if needed)
InstanceSetting.get("instance_domain")
InstanceSetting.get_with_fallback("rails_log_level", "RAILS_LOG_LEVEL", "info")
```

### Cache Management

Configuration values are cached for performance. To clear the cache:

```ruby
# Clear all cached configuration
LibreverseInstance::Application.reset_all_cached_config!

# Or use the rake task
rake instance_settings:reset_cache
```

## Command Line Management

### Rake Tasks

```bash
# Initialize default settings
rake instance_settings:initialize

# Show current configuration
rake instance_settings:show

# Validate configuration
rake instance_settings:validate

# Reset configuration cache
rake instance_settings:reset_cache
```

### Example Output

```bash
$ rake instance_settings:show
Current Instance Configuration:
==================================================
Instance Domain : localhost
Rails Log Level : info
Allowed Hosts : localhost
EEA Mode Enabled : Yes
Force SSL : No
No SSL : No
CORS Origins : *
Application Port : 3000

Database Settings Count: 8
```

## Deployment Considerations

### Environment Variables (Optional)

While database settings take priority, you can still use environment variables for:

- Initial deployment before database setup
- Container orchestration defaults
- CI/CD pipeline configuration
- Emergency overrides

### Database Initialization

The system automatically initializes default settings when:

- The application starts for the first time
- No instance settings exist in the database
- You run `rake instance_settings:initialize`

### Configuration Changes

- **Database changes**: Take effect immediately (may require cache reset)
- **Environment variable changes**: Require application restart
- **Code changes**: Require application restart

## Migration from Environment Variables

If you're migrating from a purely environment variable-based setup:

1. Your existing environment variables will be used as fallbacks
2. Use the admin interface to set database values
3. Gradually remove environment variables from deployment files
4. Database settings will take precedence automatically

## Security Notes

- Only admin users can modify instance settings
- All configuration changes are logged with user information
- Input validation prevents invalid configurations
- SSL and security settings have additional validation logic

## Troubleshooting

### Common Issues

1. **Settings not taking effect**: Clear the configuration cache
2. **Validation errors**: Check the logs and use `rake instance_settings:validate`
3. **Missing defaults**: Run `rake instance_settings:initialize`

### Debug Commands

```bash
# Check current configuration
rake instance_settings:show

# Validate settings
rake instance_settings:validate

# View logs for configuration changes
tail -f log/production.log | grep "Instance"
```
