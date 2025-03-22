# Configure additional security headers

Rails.application.config.action_dispatch.default_headers.merge!(
  # Enable HTTP Strict Transport Security
  "Strict-Transport-Security" => "max-age=31536000; includeSubDomains",

  # Prevent MIME type sniffing
  "X-Content-Type-Options" => "nosniff",

  # Prevent clickjacking
  "X-Frame-Options" => "SAMEORIGIN",

  # Enable XSS protection in browsers
  "X-XSS-Protection" => "1; mode=block",

  # Control browser features
  "Permissions-Policy" => "accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()"
)
