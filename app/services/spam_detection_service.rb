# frozen_string_literal: true
# shareable_constant_value: literal

class SpamDetectionService
  SUSPICIOUS_PATTERNS = [
    # Common spam patterns
    /\b(viagra|cialis|casino|poker|loan|mortgage|credit)\b/i,
    /\b(make.*money|work.*home|earn.*\$|free.*money)\b/i,
    /\b(click.*here|visit.*site|check.*out)\b/i,
    # URL patterns
    %r{https?://[^\s]+},
    # Excessive repetition
    /(.)\1{5,}/,
    # Multiple exclamation marks
    /!{3,}/
  ].freeze

  SUSPICIOUS_IPS_CACHE_KEY = "spam_detection:suspicious_ips"
  RATE_LIMIT_CACHE_KEY = "spam_detection:rate_limit"

  def initialize(request, params = {})
    @request = request
    @params = params
    @ip = request.remote_ip
  end

  def suspicious_content?
    return false unless content_fields.any?

    content_text = extract_content_text
    return false if content_text.blank?

    SUSPICIOUS_PATTERNS.any? { |pattern| content_text.match?(pattern) }
  end

  def rate_limited?
    # Check if IP is making too many requests
    cache_key = "#{RATE_LIMIT_CACHE_KEY}:#{@ip}"
    current_count = Rails.cache.read(cache_key) || 0

    # Allow 10 requests per minute per IP
    if current_count >= 10
      true
    else
      Rails.cache.write(cache_key, current_count + 1, expires_in: 1.minute)
      false
    end
  end

  def suspicious_ip?
    # Check if IP is in suspicious list
    suspicious_ips = Rails.cache.read(SUSPICIOUS_IPS_CACHE_KEY) || Set.new
    suspicious_ips.include?(@ip)
  end

  def mark_ip_suspicious!
    suspicious_ips = Rails.cache.read(SUSPICIOUS_IPS_CACHE_KEY) || Set.new
    suspicious_ips.add(@ip)
    Rails.cache.write(SUSPICIOUS_IPS_CACHE_KEY, suspicious_ips, expires_in: 24.hours)
  end

  def user_agent_suspicious?
    user_agent = @request.user_agent
    return true if user_agent.blank?

    # Common bot patterns
    bot_patterns = [
      /bot/i, /crawler/i, /spider/i, /scraper/i,
      /curl/i, /wget/i, /python/i, /java/i
    ]

    bot_patterns.any? { |pattern| user_agent.match?(pattern) }
  end

  def analyze_threat_level
    threats = []
    threats << :suspicious_content if suspicious_content?
    threats << :rate_limited if rate_limited?
    threats << :suspicious_ip if suspicious_ip?
    threats << :suspicious_user_agent if user_agent_suspicious?

    {
      level: threat_level(threats.length),
      threats: threats,
      score: threats.length
    }
  end

  def log_spam_attempt(type, additional_data = {})
    Rails.logger.tagged("SECURITY", "SPAM") do
      Rails.logger.warn({
        event: "spam_detected",
        type: type,
        ip: @ip,
        user_agent: @request.user_agent&.truncate(200),
        path: @request.fullpath,
        method: @request.method,
        timestamp: Time.current.iso8601,
        **additional_data
      }.to_json)
    end

    # Mark IP as suspicious if multiple spam attempts
    mark_ip_suspicious! if type != :rate_limit
  end

  private

  def extract_content_text
    content_fields.map { |field| @params[field].to_s }.join(" ")
  end

  def content_fields
    # Common field names that might contain user content
    content_field_names = %w[
      title description content message body text comment
      experience_title experience_description
    ]

    @params.select { |key, _| content_field_names.include?(key.to_s) }
  end

  def threat_level(score)
    case score
    when 0
      :low
    when 1
      :medium
    when 2..3
      :high
    else
      :critical
    end
  end
end
