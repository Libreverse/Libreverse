# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

class OobGcMiddleware
  def initialize(app)
    @app = app
    @request_count = 0
  end

  def call(env)
    status, headers, body = @app.call(env)
    @request_count += 1
    headers["!~Request-OOB-Work"] = "true" if (@request_count % 5).zero?
    [ status, headers, body ]
  end
end
