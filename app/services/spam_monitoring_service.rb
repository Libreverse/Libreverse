# Admin service for monitoring spam detection metrics
class SpamMonitoringService
  METRICS_CACHE_KEY = "spam_monitoring:metrics".freeze
  RECENT_ATTEMPTS_KEY = "spam_monitoring:recent_attempts".freeze

  def self.record_spam_attempt(type, ip, details = {})
    # Update metrics
    metrics = Rails.cache.read(METRICS_CACHE_KEY) || initialize_metrics

    metrics[:total_attempts] += 1
    metrics[:attempts_by_type][type] = (metrics[:attempts_by_type][type] || 0) + 1
    metrics[:attempts_by_ip][ip] = (metrics[:attempts_by_ip][ip] || 0) + 1
    metrics[:last_updated] = Time.current.iso8601

    Rails.cache.write(METRICS_CACHE_KEY, metrics, expires_in: 24.hours)

    # Record recent attempt
    recent_attempts = Rails.cache.read(RECENT_ATTEMPTS_KEY) || []
    recent_attempts.unshift({
                              type: type,
                              ip: ip,
                              timestamp: Time.current.iso8601,
                              **details
                            })

    # Keep only last 100 attempts
    recent_attempts = recent_attempts.first(100)
    Rails.cache.write(RECENT_ATTEMPTS_KEY, recent_attempts, expires_in: 24.hours)
  end

  def self.metrics
    Rails.cache.read(METRICS_CACHE_KEY) || initialize_metrics
  end

  def self.get_recent_attempts(limit = 50)
    recent_attempts = Rails.cache.read(RECENT_ATTEMPTS_KEY) || []
    recent_attempts.first(limit)
  end

  def self.get_top_offending_ips(limit = 10)
    spam_metrics = metrics
    spam_metrics[:attempts_by_ip]
      .sort_by { |_ip, count| -count }
      .first(limit)
      .to_h
  end

  def self.spam_summary
    spam_metrics = metrics
    recent_attempts = get_recent_attempts(100)

    {
      total_attempts: spam_metrics[:total_attempts],
      attempts_last_hour: recent_attempts.count do |attempt|
        Time.zone.parse(attempt[:timestamp]) > 1.hour.ago
      end,
      attempts_last_24h: recent_attempts.count do |attempt|
        Time.zone.parse(attempt[:timestamp]) > 24.hours.ago
      end,
      top_spam_types: spam_metrics[:attempts_by_type].sort_by { |_type, count| -count }.first(5).to_h,
      top_offending_ips: get_top_offending_ips(5),
      last_updated: spam_metrics[:last_updated]
    }
  end

  def self.clear_metrics!
    Rails.cache.delete(METRICS_CACHE_KEY)
    Rails.cache.delete(RECENT_ATTEMPTS_KEY)
  end

  def self.initialize_metrics
    {
      total_attempts: 0,
      attempts_by_type: {},
      attempts_by_ip: {},
      last_updated: Time.current.iso8601
    }
  end
end
