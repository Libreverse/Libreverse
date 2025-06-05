# frozen_string_literal: true

# Comprehensive spam detection concern integrating invisible_captcha gem with advanced detection
module SpamDetection
  extend ActiveSupport::Concern

  included do
    # NOTE: Controllers should individually configure invisible_captcha as needed
    # Example: invisible_captcha only: [:create, :update], on_spam: :handle_honeypot_spam, on_timestamp_spam: :handle_timestamp_spam
    # This concern provides the spam handling methods but doesn't enforce a default configuration
  end

  private

  # Main entry point for comprehensive spam detection beyond honeypot/timestamp
  def detect_and_handle_spam(additional_params = {})
    return false unless should_check_for_spam?

    # Create spam detection service instance
    spam_service = SpamDetectionService.new(request, params.merge(additional_params))
    threat_analysis = spam_service.analyze_threat_level

    if threat_analysis[:threats].any?
      handle_advanced_spam_detection(threat_analysis)
      return true
    end

    false
  end

  # Handle honeypot spam detection - called by invisible_captcha gem
  def handle_honeypot_spam
    log_spam_attempt(:honeypot, { detection_method: "invisible_captcha_honeypot" })

    flash[:alert] = if Rails.env.development?
      "Development: Spam detected (honeypot triggered). This helps test anti-spam functionality."
    else
      t("invisible_captcha.spam_detection.honeypot_triggered",
        default: "There was an error with your submission.")
    end

    redirect_to_safe_location
  end

  # Handle timestamp spam detection - called by invisible_captcha gem
  def handle_timestamp_spam
    log_spam_attempt(:timestamp, { detection_method: "invisible_captcha_timestamp" })

    flash[:alert] = if Rails.env.development?
      "Development: Form submitted too quickly (timestamp validation). This helps test anti-spam functionality."
    else
      t("invisible_captcha.timestamp_error_message",
        default: "Please wait a moment before submitting.")
    end

    redirect_to_safe_location
  end

  # Handle advanced spam detection (content, rate limiting, etc.)
  def handle_advanced_spam_detection(threat_analysis)
    primary_threat = threat_analysis[:threats].first
    threat_level = threat_analysis[:level]

    log_spam_attempt(primary_threat, {
                       threat_level: threat_level,
                       threats: threat_analysis[:threats],
                       detection_method: "advanced_analysis"
                     })

    # Apply progressive security measures based on threat level
    apply_security_measures(threat_level)

    # Set user-friendly message
    flash[:alert] = get_spam_message(primary_threat, threat_level)

    redirect_to_safe_location
  end

  # Enhanced logging method with threat analysis
  def log_spam_attempt(spam_type, additional_data = {})
    # Record in monitoring service for admin dashboard
    SpamMonitoringService.record_spam_attempt(
      spam_type,
      request.remote_ip,
      {
        user_agent: request.user_agent&.truncate(200),
        path: request.fullpath,
        method: request.method,
        controller: controller_name,
        action: action_name,
        **additional_data
      }
    )

    # Log to Rails logger for debugging
    Rails.logger.tagged("SECURITY", "SPAM") do
      Rails.logger.warn(
        "[SPAM] #{spam_type.upcase} detected - " \
        "IP: #{request.remote_ip}, " \
        "Path: #{request.fullpath}, " \
        "Method: #{request.method}, " \
        "Controller: #{controller_name}##{action_name}, " \
        "User-Agent: #{request.user_agent&.truncate(100)}" \
        "#{additional_data.any? ? ", Additional: #{additional_data.inspect}" : ''}"
      )
    end
  end

  # Apply security measures based on threat level
  def apply_security_measures(threat_level)
    case threat_level
    when :critical
      flag_ip_as_suspicious
      Rails.logger.error("[SECURITY] Critical spam threat detected from #{request.remote_ip}")
    when :high
      flag_ip_as_suspicious if repeated_offender?
    end
  end

  # Flag IP as suspicious in cache
  def flag_ip_as_suspicious
    suspicious_ips = Rails.cache.read("spam_protection:suspicious_ips") || Set.new
    suspicious_ips.add(request.remote_ip)
    Rails.cache.write("spam_protection:suspicious_ips", suspicious_ips, expires_in: 24.hours)
  end

  # Check if IP is a repeat offender
  def repeated_offender?
    cache_key = "spam_protection:offender:#{request.remote_ip}"
    offense_count = Rails.cache.read(cache_key) || 0
    Rails.cache.write(cache_key, offense_count + 1, expires_in: 1.hour)
    offense_count >= 3
  end

  # Get appropriate message for spam type and threat level
  def get_spam_message(spam_type, threat_level)
    case threat_level
    when :critical
      "#{t('invisible_captcha.spam_detection.general_spam')} #{t('flash.please_try_again')}"
    when :high
      t("invisible_captcha.spam_detection.honeypot_triggered")
    else
      case spam_type
      when :suspicious_content
        t("flash.content_flagged", default: "Your submission contains content that appears to be spam.")
      when :rate_limited
        t("flash.too_many_requests", default: "You're submitting forms too quickly. Please wait a moment.")
      when :suspicious_user_agent
        t("flash.suspicious_activity", default: "Suspicious activity detected. Please try again later.")
      else
        t("invisible_captcha.spam_detection.general_spam", default: "Your submission appears to be spam. Please try again.")
      end
    end
  end

  # Check if we should perform spam detection
  def should_check_for_spam?
    # Skip spam detection for certain paths or conditions
    return false if request.path.in?([ "/robots.txt", "/.well-known/security.txt", "/.well-known/privacy.txt" ])
    return false if request.path.start_with?("/admin") # Allow admin routes

    true
  end

  # Safe redirect that prevents open redirects
  def redirect_to_safe_location
    redirect_location = if request.referer.present? &&
                           request.referer.start_with?(request.base_url)
      request.referer
    else
      root_path
    end

    redirect_to redirect_location
  end

  # Legacy method for backward compatibility
  def redirect_to_spam_page
    handle_honeypot_spam
  end

  # Alternative legacy method name
  def redirect_to_previous_page_or_root
    redirect_to_safe_location
  end
end
