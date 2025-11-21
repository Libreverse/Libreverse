# frozen_string_literal: true
# shareable_constant_value: literal

require "voight_kampff"

# Enhanced spam protection concern that combines invisible_captcha and ActiveHashcash
# This provides dual-layer bot protection:
# 1. invisible_captcha: honeypot and timestamp validation
# 2. ActiveHashcash: proof-of-work requiring JavaScript computation
# 3. Bot detection cookie check (botd cookie)
# 4. User agent bot detection via voight-kampff
module EnhancedSpamProtection
  extend ActiveSupport::Concern
  include ActiveHashcash

  included do
    # Provide the enhanced helper method for forms
    helper_method :enhanced_spam_protection_fields if respond_to?(:helper_method)
  end

  # Enhanced spam protection that combines both systems
  def check_enhanced_spam_protection
    # Check bot detection first - if it fails, block the request
    return unless check_bot_protection

    # Skip hashcash for experience creation/update only
    if controller_name == "experiences" && %w[create update].include?(action_name)
      # Hashcash disabled for experience forms only
      Rails.logger.info "[EnhancedSpamProtection] Skipping hashcash for experience #{action_name}"
    else
      # Both protections should pass for the request to be valid
      # invisible_captcha is handled by its own before_action callbacks
      # We handle ActiveHashcash here
      check_hashcash
    end
  end

  # Bot detection check for high/highest protection actions
  def check_bot_protection
    Rails.logger.info "[EnhancedSpamProtection] Running bot detection checks for IP: #{request.remote_ip}, Path: #{request.fullpath}"

    # Check if botd cookie indicates this is a bot
    Rails.logger.info "[EnhancedSpamProtection] Checking botd cookie - Value: #{cookies[:botd].inspect}"
    if bot_detection_cookie_indicates_bot?
      log_spam_attempt(:bot_cookie, {
                         detection_method: "botd_cookie",
                         cookie_value: cookies[:botd]
                       })

      flash[:alert] = if Rails.env.development?
        "Development: Bot detection cookie indicates bot behavior."
      else
        t("spam_protection.bot_detected",
          default: "Automated behavior detected. Please try again.")
      end

      redirect_to_safe_location
      return false
    end
    Rails.logger.info "[EnhancedSpamProtection] botd cookie check passed"

    # Check if user agent is detected as bot by voight-kampff
    Rails.logger.info "[EnhancedSpamProtection] Checking user agent with voight-kampff - UA: #{request.user_agent}"
    if user_agent_indicates_bot?
      log_spam_attempt(:bot_user_agent, {
                         detection_method: "voight_kampff",
                         user_agent: request.user_agent
                       })

      flash[:alert] = if Rails.env.development?
        "Development: User agent detected as bot by voight-kampff."
      else
        t("spam_protection.bot_detected",
          default: "Automated behavior detected. Please try again.")
      end

      redirect_to_safe_location
      return false
    end
    Rails.logger.info "[EnhancedSpamProtection] voight-kampff user agent check passed"

    Rails.logger.info "[EnhancedSpamProtection] All bot detection checks passed"
    true
  end

  # Override hashcash failure to match our existing spam handling
  def hashcash_after_failure
    log_spam_attempt(:hashcash, {
                       detection_method: "active_hashcash",
                       hashcash_param: hashcash_param,
                       hashcash_resource: hashcash_resource,
                       hashcash_bits: hashcash_bits
                     })

    flash[:alert] = if Rails.env.development?
      "Development: Hashcash validation failed. This helps test anti-spam functionality."
    else
      t("spam_protection.hashcash_failed",
        default: "Please ensure JavaScript is enabled and try again.")
    end

    redirect_to_safe_location
  end

  # Override hashcash success for logging
  def hashcash_after_success
    Rails.logger.info "[HASHCASH] Valid stamp accepted - " \
                      "IP: #{hashcash_ip_address}, " \
                      "Path: #{hashcash_request_path}, " \
                      "Bits: #{hashcash_bits}"
  end

  # Override hashcash IP to use the same method as SpamDetection
  def hashcash_ip_address
    request.remote_ip
  end

  # Provide context for stamps that matches our monitoring system
  def hashcash_stamp_context
    {
      controller: controller_name,
      action: action_name,
      user_agent: request.user_agent&.truncate(200),
      referer: request.referer&.truncate(200)
    }
  end

  # Helper method to generate both protection fields
  def enhanced_spam_protection_fields(options = {})
    fields_html = "".html_safe

    # Add invisible captcha
    fields_html += invisible_captcha(options) if respond_to?(:invisible_captcha)

    # Add hashcash field
    fields_html += hashcash_hidden_field_tag

    fields_html
  end

  private

  # Check if bot detection cookie indicates this is a bot
  def bot_detection_cookie_indicates_bot?
    # Check if botd cookie is present and set to "0" (not a bot)
    # If cookie is missing, not "0", or any other value, consider it potentially a bot
    botd_value = cookies[:botd]

    # Allow if cookie is explicitly set to "0" (not a bot)
    return false if botd_value == "0"

    # Block if cookie is missing, empty, or any other value
    true
  end

  # Check if user agent is detected as bot by voight-kampff
  def user_agent_indicates_bot?
    return false if request.user_agent.blank?

    begin
      VoightKampff.bot?(request.user_agent)
    rescue StandardError => e
      Rails.logger.error "[EnhancedSpamProtection] Error in bot detection: #{e.message}"
      false # Default to not blocking if detection fails
    end
  end

  # Use the same spam logging and redirect methods as SpamDetection concern
  def log_spam_attempt(spam_type, additional_data = {})
    if defined?(super)
      super(spam_type, additional_data)
    else
      Rails.logger.warn "[SPAM] #{spam_type.upcase} detected - " \
                        "IP: #{request.remote_ip}, " \
                        "Path: #{request.fullpath}, " \
                        "Additional: #{additional_data.inspect}"
    end
  end

  def redirect_to_safe_location
    if defined?(super)
      super
    else
      safe_path = request.referer&.start_with?(request.base_url) ? request.referer : root_path
      redirect_to safe_path
    end
  end
end
