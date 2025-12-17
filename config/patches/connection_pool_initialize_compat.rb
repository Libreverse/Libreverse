# frozen_string_literal: true
# shareable_constant_value: literal

# Compatibility patch:
# ActiveSupport::Cache::RedisCacheStore (Rails 8.1.1) wraps its Redis client in
# `ConnectionPool` by calling:
#   ConnectionPool.new(pool_options) { ... }
#
# where `pool_options` is a Hash.
#
# connection_pool >= 3 switched to a keyword-only `initialize(**options)`.
# Passing a positional Hash raises:
#   wrong number of arguments (given 1, expected 0)
#
# This shim accepts an optional positional Hash and forwards it as keywords.

begin
  require "connection_pool"

  ConnectionPool.class_eval do
    unless method_defined?(:__libreverse_original_initialize)
      alias_method :__libreverse_original_initialize, :initialize
    end

    def initialize(options = nil, **kwargs, &block)
      if options.is_a?(Hash) && kwargs.empty?
        __libreverse_original_initialize(**options, &block)
      elsif options.nil?
        __libreverse_original_initialize(**kwargs, &block)
      else
        # Unexpected call style; fall back to original behavior.
        __libreverse_original_initialize(options, **kwargs, &block)
      end
    end
  end
rescue StandardError
  # Avoid blocking boot if upstream changes.
  nil
end
