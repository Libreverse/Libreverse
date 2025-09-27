# GDPR-Compliant Error Tracking Configuration
# This configuration minimizes personal data collection while maintaining debugging capability
Sentry.init do |config|
  # GlitchTip DSN (public, safe to hardcode)
  config.dsn = "https://dff68bb3ecd94f9faa29a454704040e8@app.glitchtip.com/12078"

  # Only enable in production and staging
  config.enabled_environments = %w[production staging]

  # GDPR Compliance: Remove all personal data before sending
  config.before_send = lambda do |event, _hint|
    # Remove request data that may contain personal information
    if event.request.is_a?(Hash)
      event.request.delete(:headers)
      event.request.delete(:cookies)
      event.request.delete(:data)
    end

    # Clear user context to prevent sending user data
    event.user = {}

    event
  end

  # GDPR: Disable sending default PII (Personally Identifiable Information)
  config.send_default_pii = false

  # Disable performance monitoring to reduce data collection
  config.traces_sample_rate = 0.0

  # Minimize breadcrumbs collection (avoid manipulating BreadcrumbBuffer directly)
  config.breadcrumbs_logger = []
  config.max_breadcrumbs = 0

  # Set release and environment
  config.release = ENV.fetch("APP_REVISION") { nil }
  config.environment = Rails.env

  # Only capture errors and fatal level logs
  config.sdk_logger.level = Logger::ERROR

  # Exclude certain exception types that may contain personal data
  config.excluded_exceptions += [
    "ActionController::BadRequest",
    "ActionController::UnknownFormat",
    "ActionController::ParameterMissing"
  ]
end
