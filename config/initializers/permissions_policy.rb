# Define an application-wide HTTP permissions policy.
# See https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Permissions-Policy
# for more information.

Rails.application.config.permissions_policy do |policy|
  # Restrict access to sensitive browser features
  policy.camera      :none
  policy.microphone  :none
  policy.geolocation :none
  policy.usb         :none
  policy.payment     :none
  policy.gyroscope   :none
  policy.accelerometer :none
  policy.magnetometer :none
  policy.midi :none
  policy.display_capture :none
  policy.autoplay    :none
  # policy.battery     :none  # Removed - not supported in Rails 8.0.1
  # policy.document_domain :none  # Removed - not supported in Rails 8.0.1

  # Allow features that might be needed
  policy.fullscreen  :self
  policy.screen_wake_lock :self

  # Explicitly deny access to other features
  # policy.interest_cohort :none  # Removed - not supported in Rails 8.0.1 (Disallow FLoC)
end
