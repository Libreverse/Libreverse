# frozen_string_literal: true

# Additional Secure HTTP Headers Configuration
Rails.application.config.action_dispatch.default_headers.merge!(
  "Strict-Transport-Security" => "max-age=31536000; includeSubDomains",
  "X-Content-Type-Options" => "nosniff",
  "X-Frame-Options" => "SAMEORIGIN",
  "X-XSS-Protection" => "1; mode=block"
)
