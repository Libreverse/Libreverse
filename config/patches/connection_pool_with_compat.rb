# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# Compatibility patch:
# Some callers (notably redis-client pooled wrappers and/or Rails cache plumbing)
# may call ConnectionPool#with with a positional timeout argument.
#
# In connection_pool >= 3, `with` is implemented without positional arguments.
# When a caller passes a timeout, Ruby raises:
#   wrong number of arguments (given 1, expected 0)
#
# We accept (and currently ignore) the optional argument and delegate to the
# original implementation.
#
# This keeps cache reads/writes from crashing request handling.

begin
  require "connection_pool"

  ConnectionPool.class_eval do
    alias_method :__libreverse_original_with, :with unless method_defined?(:__libreverse_original_with)

    def with(*_args, &block)
      __libreverse_original_with(&block)
    end
  end
rescue StandardError
  # Avoid blocking boot if upstream changes.
  nil
end
