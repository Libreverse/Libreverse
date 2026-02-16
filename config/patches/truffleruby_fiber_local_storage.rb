# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# TruffleRuby compatibility shim.
#
# Rails 8.1's ActiveSupport::EventReporter uses Fiber-local storage via the
# Ruby core API:
#   Fiber[:key] / Fiber[:key] = value
#
# On TruffleRuby (as of 25.0.0 / Ruby 3.3.7 compatibility), Fiber.[]/[]= may not
# be implemented, causing request-time crashes like:
#   NoMethodError: undefined method `[]' for class Fiber
#
# This patch provides Fiber-local storage backed by an ivar on Fiber.current.
# It is intentionally minimal and only applied when needed.

return unless RUBY_ENGINE == "truffleruby"

unless Fiber.respond_to?(:[])
  class << Fiber
    def [](key)
      current = Fiber.current
      store = current.instance_variable_get(:@__libreverse_fiber_local)
      unless store.is_a?(Hash)
        store = {}
        current.instance_variable_set(:@__libreverse_fiber_local, store)
      end
      store[key]
    end

    def []=(key, value)
      current = Fiber.current
      store = current.instance_variable_get(:@__libreverse_fiber_local)
      unless store.is_a?(Hash)
        store = {}
        current.instance_variable_set(:@__libreverse_fiber_local, store)
      end
      store[key] = value
      store[key]
    end
  end
end

# Some code may use Fiber.current[:key]; provide instance variants too.
unless Fiber.method_defined?(:[])
  class Fiber
    def [](key)
      store = instance_variable_get(:@__libreverse_fiber_local)
      store.is_a?(Hash) ? store[key] : nil
    end

    def []=(key, value)
      store = instance_variable_get(:@__libreverse_fiber_local)
      unless store.is_a?(Hash)
        store = {}
        instance_variable_set(:@__libreverse_fiber_local, store)
      end
      store[key] = value
      store[key]
    end
  end
end
