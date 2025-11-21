# frozen_string_literal: true
# shareable_constant_value: literal

class OobGcMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)
    # Trigger every 5 requests (adjust as needed)
    headers["!~Request-OOB-Work"] = "true" if rand(5).zero?
    [ status, headers, body ]
  end
end
