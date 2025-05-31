# frozen_string_literal: true

InvisibleCaptcha.setup do |config|
  # Configure the default time threshold (in seconds) for when the form is submitted
  # Forms submitted faster than this are considered spam
  # More lenient in development to prevent issues during testing
  config.timestamp_threshold = Rails.env.development? ? 1 : 3
  config.timestamp_enabled   = true

  # Configure expanded honeypot field names that bots will try to fill
  # Using a diverse set of field names that bots commonly target
  config.honeypots = %i[
    website subtitle email_address phone_number full_name first_name last_name
    address city state country zip_code postal_code company organization
    comment message description notes url homepage link verification
  ]

  # Configure whether to use visual honeypots (keep false for production)
  config.visual_honeypots = false

  # Configure spinner (visual element to encourage users to wait)
  config.spinner_enabled = true

  # Injectable styles for the honeypot field (enabled for better CSP compliance)
  config.injectable_styles = true

  # Use I18n for localized error messages instead of hardcoded strings
  # These will fallback to the I18n keys if translations are available
  # config.sentence_for_humans     = "This field should be left empty"
  # config.timestamp_error_message = "Form submitted too quickly. Please wait and try again."
end

# Set up global spam detection event handler for logging and monitoring
ActiveSupport::Notifications.subscribe("invisible_captcha.spam_detected") do |*_args, data|
  # Enhanced logging for development debugging
  if Rails.env.development?
    Rails.logger.warn(
      "[INVISIBLE_CAPTCHA DEBUG] #{data[:message]} - " \
      "IP: #{data[:remote_ip]}, " \
      "User-Agent: #{data[:user_agent]}, " \
      "Controller: #{data[:controller]}##{data[:action]}, " \
      "URL: #{data[:url]}, " \
      "Session ID: #{data[:session_id] || 'N/A'}, " \
      "Timestamp in session: #{data[:timestamp_in_session] || 'N/A'}"
    )
  else
    Rails.logger.warn(
      "[SPAM DETECTED] #{data[:message]} - " \
      "IP: #{data[:remote_ip]}, " \
      "User-Agent: #{data[:user_agent]}, " \
      "Controller: #{data[:controller]}##{data[:action]}, " \
      "URL: #{data[:url]}"
    )
  end

  # You can add additional spam handling here:
  # - Store in database for analysis
  # - Send alerts to admins
  # - Update IP reputation scores
  # - Trigger additional security measures
end
