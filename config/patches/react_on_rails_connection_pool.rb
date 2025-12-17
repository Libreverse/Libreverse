# frozen_string_literal: true
# shareable_constant_value: literal

# Compatibility patch:
# react_on_rails 16.0.0 calls ConnectionPool.new(options_hash) with a positional
# Hash in its server rendering pool.
#
# connection_pool >= 3 uses a keyword-only initialize, so the positional Hash
# raises:
#   wrong number of arguments (given 1, expected 0)
#
# Apply immediately after Bundler.require (so ReactOnRails is loaded), but before
# Rails initialization runs engine initializers.
#
begin
  target = ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript

  target.singleton_class.class_eval do
    define_method(:reset_pool) do
      options = {
        size: ReactOnRails.configuration.server_renderer_pool_size,
        timeout: ReactOnRails.configuration.server_renderer_timeout
      }

      @js_context_pool = ConnectionPool.new(**options) { create_js_context }
    end
  end
rescue NameError
  # react_on_rails not present / not loaded.
  nil
rescue StandardError
  # Avoid blocking boot if upstream changes.
  nil
end
