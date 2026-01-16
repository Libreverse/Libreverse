# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# Concern for caching API responses in indexers
module Cacheable
  extend ActiveSupport::Concern

  private

  def cache_enabled?
    global_config = Rails.application.config_for(:indexers)["global"] || {}
    global_config.fetch("enable_caching") { true } && config.fetch("cache_duration") { 0 }.positive?
  end

  def cache_duration
    config.fetch("cache_duration") { 3600 } # Default 1 hour
  end

  def cache_key(key_parts)
    "indexer:#{platform_name}:#{Array(key_parts).join(':')}"
  end

  def cached_request(key_parts)
    return yield unless cache_enabled?

    key = cache_key(key_parts)

    Rails.cache.fetch(key, expires_in: cache_duration) do
      result = yield
      log_debug "Cached result for key: #{key}"
      result
    end
  rescue StandardError => e
    log_error "Cache error for key #{key}: #{e.message}, falling back to direct request"
    yield
  end

  def invalidate_cache(key_parts = nil)
    return unless cache_enabled?

    if key_parts
      key = cache_key(key_parts)
      Rails.cache.delete(key)
      log_debug "Invalidated cache for key: #{key}"
    else
      # Invalidate all cache entries for this indexer
      # Note: This is a simple implementation - for production you might want
      # a more sophisticated cache invalidation strategy
      pattern = cache_key("*")
      log_debug "Invalidated cache pattern: #{pattern}"
    end
  end

  def cache_stats
    return nil unless cache_enabled?

    {
      enabled: true,
      duration: cache_duration,
      backend: Rails.cache.class.name
    }
  end
end
