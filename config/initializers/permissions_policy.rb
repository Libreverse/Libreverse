# frozen_string_literal: true

# Permissions Policy Configuration
Rails.application.config.permissions_policy do |policy|
  # Restrict access to sensitive browser features
  policy.camera         :none
  policy.microphone     :none
  policy.geolocation    :none
  policy.usb            :none
  policy.payment        :none
  policy.gyroscope      :none
  policy.accelerometer  :none
  policy.magnetometer   :none
  policy.midi           :none
  policy.display_capture :none
  policy.autoplay :none
end
