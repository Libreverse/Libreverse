require "active_support/key_generator"

InvisibleCaptcha.setup do |config|
  # Configure the default time threshold (in seconds) for when the form is submitted
  # Forms submitted faster than this are considered spam
  # More lenient in development to prevent issues during testing
  config.timestamp_threshold = Rails.env.development? ? 2 : 4
  config.timestamp_enabled = !Rails.env.test?

  # Configure whether to use visual honeypots (ALWAYS false - honeypots should be invisible)
  config.visual_honeypots = false

  # Configure spinner (visual element to encourage users to wait)
  config.spinner_enabled = false

  # Injectable styles for the honeypot field (disabled - we'll handle CSS ourselves)
  config.injectable_styles = false

  # Set the internal secret to a derived key from Rails.application.secret_key_base for consistency
  config.secret = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base, iterations: 1000).generate_key("invisible_captcha_secret", 32).unpack1("H*")

  # Override default messages to use I18n keys
  config.sentence_for_humans = I18n.t("invisible_captcha.sentence_for_humans", default: "Please leave this field empty")
  config.timestamp_error_message = I18n.t("invisible_captcha.timestamp_error_message", default: "Form submitted too quickly. Please wait and try again.")
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

  # Record spam attempt in monitoring service
  spam_type = case data[:message]
  when /honeypot/i
    :honeypot
  when /timestamp/i
    :timestamp
  when /spinner/i
    :spinner
  else
    :unknown
  end

  # Safely record spam attempt with error handling
  begin
    SpamMonitoringService.record_spam_attempt(
      spam_type,
      data[:remote_ip],
      {
        user_agent: data[:user_agent],
        path: data[:url],
        controller: data[:controller],
        action: data[:action],
        detection_method: "invisible_captcha_notification",
        message: data[:message]
      }
    )
  rescue StandardError => e
    Rails.logger.error("[SPAM_MONITORING] Failed to record spam attempt: #{e.message}")
  end
end
