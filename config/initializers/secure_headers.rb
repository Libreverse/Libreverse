# frozen_string_literal: true
# shareable_constant_value: literal

# Keep secure_headers defaults, but let Rails manage CSP and disable automatic cookie attributes.

SecureHeaders::Configuration.default do |config|
  # Let Rails' content_security_policy.rb manage CSP instead of secure_headers
  config.csp = SecureHeaders::OPT_OUT
  # Also opt out of any report-only CSP coming from secure_headers
  config.csp_report_only = SecureHeaders::OPT_OUT

  # Disable secure_headers' automatic cookie attributes (Secure/HttpOnly/SameSite)
  config.cookies = SecureHeaders::OPT_OUT

  # (Optional) leave other defaults alone; you can still customize others here.
  # e.g. explicit defaults you want to keep/override:
  # config.x_frame_options = "SAMEORIGIN"
  # config.x_content_type_options = "nosniff"
end
