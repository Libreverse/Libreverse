# frozen_string_literal: true

# app/services/function_cache.rb
require "digest"

class FunctionCache
  NAMESPACE = "function_cache:v1".freeze

  def initialize(default_ttl: nil, max_size: 1000)
    @default_ttl = default_ttl
    @max_size = max_size
  end

  # Cache a function's result based on its name and arguments
  # Usage: FunctionCache.instance.cache(:my_function, arg1, arg2, ttl: 60) { my_function(arg1, arg2) }
  def cache(function_name, *args, ttl: @default_ttl)
    raise ArgumentError, "Block required for computation" unless block_given?

  key_str = build_key(function_name, args)
  expires_in = ttl && ttl.to_f > 0 ? ttl.to_f : nil
  Rails.cache.fetch(key_str, expires_in: expires_in) { yield }
  end

  # Delete a cached value for a specific function/args
  def delete(function_name, *args)
  Rails.cache.delete(build_key(function_name, args))
    true
  end

  # Clear the cache
  def clear
  # We cannot efficiently clear only our namespace without a key index; no-op
  # Prefer targeted delete(function_name, *args)
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
