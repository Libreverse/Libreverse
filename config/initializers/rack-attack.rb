class Rack::Attack
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  throttle("req/ip", limit: 1200, period: 1.minutes) { |req| req.ip }

  self.throttled_responder =
    lambda do |request|
      [
        429, # status
        { "Content-Type" => "text/plain", "Retry-After" => "60" }, # headers, with Retry-After
        [
          "Your traffic has been throttled because you sent too many requests. Please try again in one minute"
        ]
      ]
    end
end

Rails.application.config.middleware.use Rack::Attack
