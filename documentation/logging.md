# Application Logging Guide

This document describes the standardized logging system implemented in the application. Following these guidelines will ensure consistent and useful logging throughout the codebase.

## Logging Configuration

The application uses a centralized logging configuration in `config/initializers/logger.rb`. This ensures:

- Consistent log format across all components
- Proper log levels based on environment
- Request ID inclusion in all log messages for traceability
- Exception logging
- Integration with all Rails components (ActionCable, ActiveRecord, etc.)

## Using the Logging System

### Basic Usage

The simplest way to log in the application is to use Rails.logger directly:

```ruby
Rails.logger.info "This is an informational message"
Rails.logger.error "An error occurred: #{error.message}"
```

### Enhanced Logging with LoggingHelper

For more structured logging, use the `LoggingHelper` module:

```ruby
include LoggingHelper

# Log with component identification
log_debug("MyComponent", "This is a debug message")
log_info("MyComponent", "This is an info message")
log_warn("MyComponent", "This is a warning message")
log_error("MyComponent", "An error occurred", exception)

# Special purpose logs
log_security_event("MyComponent", "unauthorized_access", { ip: request.ip })
log_performance("MyComponent", "database_query", 35.2) # duration in ms
log_db_operation("MyComponent", "create_record", { table: "accounts", id: 123 })
log_user_activity("MyComponent", user_id, "login", { ip: request.ip })

# Performance timing
result = with_timing("MyComponent", "complex_operation") do
  # Your code here - duration will be logged automatically
  perform_complex_operation
end
```

### Using the Loggable Concern

The recommended way to add logging to your classes is with the `Loggable` concern:

```ruby
class MyService
  include Loggable

  def perform_task
    log_info "Starting task"

    # Automatically logs timing information
    with_timing "complex_calculation" do
      # Complex operation here
    end

    log_info "Task completed"
  rescue StandardError => e
    log_error "Task failed", e
    raise
  end
end
```

With the `Loggable` concern, the component name is automatically derived from the class name, making logs consistent and reducing boilerplate code.

## Log Levels

Use the appropriate log level for your messages:

- **DEBUG**: Detailed information for debugging and development
- **INFO**: General operational information
- **WARN**: Non-critical issues that might need attention
- **ERROR**: Errors that affect functionality but don't crash the application
- **FATAL**: Critical errors that cause the application to fail

## Best Practices

1. **Be Consistent**: Use the `Loggable` concern in all new classes
2. **Include Context**: Log relevant details that would help with debugging
3. **Don't Log Sensitive Data**: Never log passwords, tokens, or personal information
4. **Use Structured Logging**: For complex data, use hashes/JSON rather than concatenated strings
5. **Log Start and End**: For long-running operations, log when they start and complete
6. **Use Performance Logging**: Track timings for slow operations
7. **Log Security Events**: Always log security-related events (login attempts, authorizations, etc.)

## Viewing Logs

Logs are sent to:

- **Development**: STDOUT
- **Production**: STDOUT (to be captured by the hosting environment)

To filter logs in development:

```bash
tail -f log/development.log | grep "[ERROR]"
```

## Adding Logging to StimulusReflex

StimulusReflex automatically logs reflex operations when you include the `Loggable` concern in your reflex classes. For custom reflexes, extend `ApplicationReflex` which already includes logging:

```ruby
class MyReflex < ApplicationReflex
  def my_action
    log_info "Processing my_action with data: #{element.dataset.id}"
    # Reflex logic here
  end
end
```

## Monitoring and Alerting

Production logs should be monitored for ERROR and FATAL level messages, which may indicate issues requiring immediate attention.
