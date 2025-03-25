# Configure Rack::Attack for rate limiting
module Rack
  class Attack
    # Global rate limiting for all requests
    throttle("req/ip", limit: 300, period: 5.minutes) do |req|
      req.ip unless req.path.start_with?("/assets")
    end

    # Set up response handling
    self.throttled_responder = lambda do |_env|
      [
        429,
        { "Content-Type" => "text/xml" },
        [ Api::XmlrpcController.new.fault_response(429, "Rate limit exceeded") ]
      ]
    end
  end
end
