# frozen_string_literal: true

# Consolidate and apply all security headers at once
SECURE_HEADERS = {
  "X-Frame-Options" => "SAMEORIGIN",
  "X-Content-Type-Options" => "nosniff",
  "X-XSS-Protection" => "1; mode=block",
  "Referrer-Policy" => "strict-origin-when-cross-origin",
  "Cross-Origin-Opener-Policy" => "same-origin",
  "Cross-Origin-Resource-Policy" => "same-origin",
  "Strict-Transport-Security" => "max-age=31536000; includeSubDomains",
  "Expect-CT" => "max-age=86400, enforce",
  "X-Download-Options" => "noopen",
  "X-Permitted-Cross-Domain-Policies" => "none"
}.freeze

Rails.application.config.action_dispatch.default_headers.merge!(SECURE_HEADERS)
