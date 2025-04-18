# frozen_string_literal: true

# CORS Configuration
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "libreverse.geor.me", "libreverse.dev", "localhost:3000"

    resource "*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true,
             max_age: 86_400
  end
end
