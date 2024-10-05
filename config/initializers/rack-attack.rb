# from personal website
# config/initializers/rack_attack.rb

class Rack::Attack

  # Configuration for the cache store
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new 

  ### Throttle All Requests ###

  # Throttle all requests by IP
  throttle('req/ip', limit: 120, period: 1.minutes) do |req|
    req.ip
  end

  ### Custom Throttle Responder ###

  # Use throttled_responder instead of throttled_response
  self.throttled_responder = lambda do |request|
    # The request object here provides more context if needed
    [
      429,  # status
      {'Content-Type' => 'text/plain', 'Retry-After' => '300'},  # headers, with Retry-After
      ['Too Many Requests. Please try again later.']  # body
    ]
  end

end

# Enable Rack Attack
Rails.application.config.middleware.use Rack::Attack