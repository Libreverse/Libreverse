# adapted from personal website
class Rack::Attack

  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new 

  throttle('req/ip', limit: 120, period: 5.minutes) do |req|
    req.ip
  end

  self.throttled_responder = lambda do |request|
    [
      429,  # status
      {'Content-Type' => 'text/plain', 'Retry-After' => '300'},  # headers, with Retry-After
      ['Your traffic has been throttled because you sent too many requests. Please try again in 5 minutes (300 seconds)']
    ]
  end

end

Rails.application.config.middleware.use Rack::Attack