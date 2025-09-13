# frozen_string_literal: true

# app/services/function_cache.rb
require "digest"

class FunctionCache
  NAMESPACE = "function_cache:v1"

  def initialize(default_ttl: nil, max_size: 1000)
    @default_ttl = default_ttl
    @max_size = max_size
    @local_store = {}
  end

  # Cache a function's result based on its name and arguments
  # Usage: FunctionCache.instance.cache(:my_function, arg1, arg2, ttl: 60) { my_function(arg1, arg2) }
  # If serialize: false, the value is kept in a per-process in-memory store (not shared across processes)
  def cache(function_name, *args, ttl: @default_ttl, serialize: true, &block)
    raise ArgumentError, "Block required for computation" unless block_given?

    key_str = build_key(function_name, args)

    # Per-process cache path to avoid serialization for complex objects
    unless serialize
      entry = @local_store[key_str]
      if entry
        return entry[:value] if entry[:expires_at].nil? || Time.zone.now < entry[:expires_at]

          @local_store.delete(key_str)

      end

      value = yield
      expires_at = ttl&.to_f&.positive? ? Time.zone.now + ttl.to_f : nil
      @local_store[key_str] = { value: value, expires_at: expires_at }
      return value
    end

    # Shared cache path (serializes value), appropriate for simple objects
    expires_in = ttl&.to_f&.positive? ? ttl.to_f : nil
    Rails.cache.fetch(key_str, expires_in: expires_in, &block)
  end

  # Delete a cached value for a specific function/args
  def delete(function_name, *args)
    key = build_key(function_name, args)
    Rails.cache.delete(key)
    @local_store.delete(key)
    true
  end

  # Clear the cache
  def clear
    # We cannot efficiently clear only our namespace without a key index; clear local store only
    @local_store.clear
    false
  end

  # Close the store
  def close
    # no-op for in-memory cache
  end

  # Singleton for app-wide access
  def self.instance
    @@instance ||= new(default_ttl: 3600, max_size: 1000) # 1-hour default TTL, 1000 entries
  end

  private

  def build_key(function_name, args)
    digest = Digest::SHA256.hexdigest(Marshal.dump(args))
    "#{NAMESPACE}:#{function_name}:#{digest}"
  end
end
