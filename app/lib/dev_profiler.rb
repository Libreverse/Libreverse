# frozen_string_literal: true

# Lightweight helper to profile blocks or methods in development.
module DevProfiler
  def self.profile(name)
    return yield unless defined?(Rack::MiniProfiler) && Rails.env.development?

    Rack::MiniProfiler.step(name) { yield }
  end
end
