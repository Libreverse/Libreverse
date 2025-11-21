# frozen_string_literal: true
# shareable_constant_value: literal

require "re2"

# CORS Configuration
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Use simple origins during initialization to avoid dependency on application methods
    cors_origins = if Rails.env.development? || Rails.env.test?
      [ "http://localhost:3000", "http://127.0.0.1:3000", "http://[::1]:3000" ] # Specific localhost origins for dev
    else
      # In production, derive from instance domain
      instance_domain = ENV["INSTANCE_DOMAIN"] || "localhost"
      [ "https://#{instance_domain}", "http://#{instance_domain}" ]
    end

    origins(*cors_origins)

    resource "*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true,
             max_age: 86_400
  end
end
