# frozen_string_literal: true

require "re2"

# CORS Configuration
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    cors_env = ENV.fetch("CORS_ORIGINS") { Rails.env.development? || Rails.env.test? ? "http://localhost:3000" : nil }
    origins(*cors_env.to_s.split(RE2::Regexp.new('[,\\s]+')).reject(&:blank?))

    resource "*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true,
             max_age: 86_400
  end
end
