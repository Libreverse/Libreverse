# Lightweight helper to profile blocks or methods in development.
module DevProfiler
  def self.profile(name, &block)
    return yield unless defined?(Rack::MiniProfiler) && Rails.env.development?

    Rack::MiniProfiler.step(name, &block)
  end
end
