# frozen_string_literal: true
# shareable_constant_value: literal

# Consolidate and apply all security headers at once
#
# NOTE: In development (especially when embedding the Rails app inside the
# Electron+Vite shell), browsers can be stricter about CORP checks for documents
# served from different ports. Using `cross-origin` avoids the embed being
# blocked when COEP is enabled in the renderer.
default_corp_policy = Rails.env.development? ? "cross-origin" : "same-site"
corp_policy = ENV["CROSS_ORIGIN_RESOURCE_POLICY"].presence_in(%w[same-origin same-site cross-origin]) || default_corp_policy
coep_policy = ENV["CROSS_ORIGIN_EMBEDDER_POLICY"].presence_in(%w[require-corp credentialless])
coep_policy ||= "credentialless" if Rails.env.development?

base_headers = {
  # "X-Frame-Options" => "SAMEORIGIN",
  "X-Content-Type-Options" => "nosniff",
  "X-XSS-Protection" => "1; mode=block",
  "Referrer-Policy" => "strict-origin-when-cross-origin",
  "Cross-Origin-Opener-Policy" => "same-origin",
  "Cross-Origin-Embedder-Policy" => coep_policy,
  "Cross-Origin-Resource-Policy" => corp_policy,
  "Expect-CT" => "max-age=86400, enforce",
  "X-Download-Options" => "noopen",
  "X-Permitted-Cross-Domain-Policies" => "none"
}.compact

# Conditionally merge HSTS based on production environment
base_headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains" if Rails.env.production?

SECURE_HEADERS = base_headers.freeze

Rails.application.config.action_dispatch.default_headers.merge!(SECURE_HEADERS)
Rails.application.config.action_dispatch.default_headers.delete("X-Frame-Options")

# Some parts of Rails snapshot default headers early; update the response defaults too
if defined?(ActionDispatch::Response)
  ActionDispatch::Response.default_headers.merge!(SECURE_HEADERS)
  ActionDispatch::Response.default_headers.delete("X-Frame-Options")
end
