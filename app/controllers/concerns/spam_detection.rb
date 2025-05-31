# frozen_string_literal: true

# Enhanced spam detection module for comprehensive protection
module SpamDetection
  extend ActiveSupport::Concern

  included do
    # Default invisible_captcha configuration for all controllers
    # Individual controllers can override these settings
    invisible_captcha only: [], # Override in specific controllers
                      honeypot: nil, # Use random honeypot
                      on_spam: :handle_comprehensive_spam_detection,
                      on_timestamp_spam: :handle_timestamp_spam_detection
  end

  private

  def handle_comprehensive_spam_detection
    spam_type = determine_spam_type
    threat_level = analyze_threat_level

    log_spam_detection(spam_type, threat_level)
    set_spam_flash_message(spam_type, threat_level)

    # Additional security measures for high threats
    implement_security_measures(threat_level)

    redirect_to_safe_location
  end

  def handle_timestamp_spam_detection
    log_spam_detection(:timestamp, :medium)

    # In development, provide more detailed feedback for debugging
    if Rails.env.development?
      Rails.logger.warn "[DEVELOPMENT] Invisible Captcha timestamp validation failed - this helps identify session or timing issues during development"
      flash[:alert] = "Development: Form submitted too quickly (invisible captcha). This helps test anti-spam functionality."
    else
      flash[:alert] = t("invisible_captcha.timestamp_error_message")
    end

    redirect_to_safe_location
  end

  def determine_spam_type
    return :honeypot if honeypot_fields_filled?
    return :content if suspicious_content_detected?
    return :rate_limit if rate_limit_exceeded?
    return :user_agent if suspicious_user_agent?

    :general
  end

  def analyze_threat_level
    threats = []
    threats << :honeypot if honeypot_fields_filled?
    threats << :content if suspicious_content_detected?
    threats << :rate_limit if rate_limit_exceeded?
    threats << :user_agent if suspicious_user_agent?
    threats << :suspicious_ip if ip_flagged_as_suspicious?

    case threats.length
    when 0..1
      :low
    when 2
      :medium
    when 3
      :high
    else
      :critical
    end
  end

  def honeypot_fields_filled?
    InvisibleCaptcha.honeypots.any? do |field|
      params[field].present? ||
        params.dig(:experience, field).present? ||
        params.dig(:account, field).present? ||
        params.dig(:user, field).present?
    end
  end

  def suspicious_content_detected?
    content_text = extract_content_for_analysis
    return false if content_text.blank?

    spam_patterns = [
      /\b(viagra|cialis|casino|poker|loan|mortgage)\b/i,
      /\b(make.*money|work.*home|earn.*\$)\b/i,
      %r{https?://[^\s]+},
      /(.)\1{5,}/, # Excessive repetition
      /!{3,}/ # Multiple exclamation marks
    ]

    spam_patterns.any? { |pattern| content_text.match?(pattern) }
  end

  def rate_limit_exceeded?
    cache_key = "spam_protection:rate_limit:#{request.remote_ip}"
    current_count = Rails.cache.read(cache_key) || 0

    if current_count >= 10 # 10 requests per minute
      true
    else
      Rails.cache.write(cache_key, current_count + 1, expires_in: 1.minute)
      false
    end
  end

  def suspicious_user_agent?
    user_agent = request.user_agent
    return true if user_agent.blank?

    bot_patterns = [
      /bot/i, /crawler/i, /spider/i, /scraper/i,
      /curl/i, /wget/i, /python/i, /java/i
    ]

    bot_patterns.any? { |pattern| user_agent.match?(pattern) }
  end

  def ip_flagged_as_suspicious?
    suspicious_ips = Rails.cache.read("spam_protection:suspicious_ips") || Set.new
    suspicious_ips.include?(request.remote_ip)
  end

  def extract_content_for_analysis
    content_fields = %w[title description content message body text comment]
    content_fields.map { |field| params[field].to_s }.join(" ")
  end

  def log_spam_detection(spam_type, threat_level)
    details = {
      threat_level: threat_level,
      user_agent: request.user_agent&.truncate(200),
      path: request.fullpath,
      method: request.method
    }

    # Record in monitoring service for admin dashboard
    SpamMonitoringService.record_spam_attempt(spam_type, request.remote_ip, details)

    # Log to Rails logger
    Rails.logger.tagged("SECURITY", "SPAM") do
      Rails.logger.warn({
        event: "spam_detected",
        spam_type: spam_type,
        threat_level: threat_level,
        ip: request.remote_ip,
        user_agent: request.user_agent&.truncate(200),
        path: request.fullpath,
        method: request.method,
        timestamp: Time.current.iso8601,
        params: request.filtered_parameters
      }.to_json)
    end
  end

  def set_spam_flash_message(spam_type, threat_level)
    flash[:alert] = case threat_level
    when :critical
      "#{t('invisible_captcha.spam_detection.general_spam')} #{t('flash.please_try_again')}"
    when :high
      t("invisible_captcha.spam_detection.honeypot_triggered")
    else
      case spam_type
      when :honeypot
        t("invisible_captcha.spam_detection.honeypot_triggered")
      when :content
        t("flash.content_flagged")
      when :rate_limit
        t("flash.too_many_requests")
      when :user_agent
        t("flash.suspicious_activity")
      else
        t("invisible_captcha.spam_detection.general_spam")
      end
    end
  end

  def implement_security_measures(threat_level)
    case threat_level
    when :critical
      flag_ip_as_suspicious
      Rails.logger.error("Critical spam threat detected from #{request.remote_ip}")
    when :high
      flag_ip_as_suspicious if repeated_offender?
    end
  end

  def flag_ip_as_suspicious
    suspicious_ips = Rails.cache.read("spam_protection:suspicious_ips") || Set.new
    suspicious_ips.add(request.remote_ip)
    Rails.cache.write("spam_protection:suspicious_ips", suspicious_ips, expires_in: 24.hours)
  end

  def repeated_offender?
    cache_key = "spam_protection:offender:#{request.remote_ip}"
    offense_count = Rails.cache.read(cache_key) || 0
    Rails.cache.write(cache_key, offense_count + 1, expires_in: 1.hour)
    offense_count >= 3
  end

  def redirect_to_safe_location
    redirect_location = if request.referer.present? &&
                           request.referer.start_with?(request.base_url)
      request.referer
    else
      root_path
    end

    redirect_to redirect_location
  end

  # Legacy method for compatibility
  def redirect_to_spam_page
    handle_comprehensive_spam_detection
  end
end
