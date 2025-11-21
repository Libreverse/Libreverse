# frozen_string_literal: true
# shareable_constant_value: literal

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

    # Shared cache path using Solid Cache (serializes value), appropriate for simple objects
    expires_in = ttl&.to_f&.positive? ? ttl.to_f : nil

    # Use Solid Cache-specific options for better performance
    cache_options = {
      expires_in: expires_in
      # NOTE: active_record_instrumentation is now disabled globally in config/cache.yml
    }

    # Add error handling for Solid Cache operations
    begin
      Rails.cache.fetch(key_str, **cache_options, &block)
    rescue StandardError => e
      # Log cache errors but don't fail the operation
      Rails.logger.warn("FunctionCache: Cache operation failed for #{function_name}: #{e.class}: #{e.message}")
      # Fall back to computing the value without caching
      yield
    end
  end

  # Delete a cached value for a specific function/args
  def delete(function_name, *args)
    key = build_key(function_name, args)
    begin
      Rails.cache.delete(key)
      @local_store.delete(key)
      true
    rescue StandardError => e
      Rails.logger.warn("FunctionCache: Delete operation failed for #{function_name}: #{e.class}: #{e.message}")
      false
    end
  end

  # Clear the cache
  def clear
    # We cannot efficiently clear only our namespace without a key index; clear local store only
    @local_store.clear
    false
  end

  # Clear all Solid Cache entries (use with caution - clears entire cache)
  def clear_all!
      Rails.cache.clear
      @local_store.clear
      true
  rescue StandardError => e
      Rails.logger.warn("FunctionCache: Clear all operation failed: #{e.class}: #{e.message}")
      false
  end

  # Get cache statistics (Solid Cache specific)
  def stats
    return {} unless Rails.cache.respond_to?(:stats)

    begin
      Rails.cache.stats
    rescue StandardError => e
      Rails.logger.warn("FunctionCache: Stats operation failed: #{e.class}: #{e.message}")
      {}
    end
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
    # Use a more efficient key building approach
    # Convert args to a stable string representation
    args_str = args.map do |arg|
      case arg
      when String, Symbol, Integer, Float, TrueClass, FalseClass, NilClass
        arg.to_s
      else
        # For complex objects, use a hash of their string representation
        # This is more stable than Marshal.dump for cache keys
        Digest::SHA256.hexdigest(arg.inspect)[0..15] # First 16 chars of hash
      end
    end.join("|")

    "#{NAMESPACE}:#{function_name}:#{args_str}"
  end
end
