# shareable_constant_value: literal
# typed: true
# frozen_string_literal: true

require "memo_wise"

# Simple per-process memoized cache for SSR'd animated icon HTML.
# Meant to avoid repeated React renderToString calls for identical props.
class AnimatedIconSsrCache
  class << self
    prepend MemoWise

    # @param cache_key [String] deterministic, unique key for the icon render
    # @yieldreturn [String] HTML-safe rendered component
    def fetch(cache_key)
      raise ArgumentError, "block required" unless block_given?

      # Use a simple instance variable cache since MemoWise doesn't handle blocks well
      @cache ||= {}
      @cache[cache_key] ||= yield
    end
  end
end
