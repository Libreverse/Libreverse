# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# ActiveHashcash configuration for additional bot protection
# This works alongside invisible_captcha for comprehensive spam protection

ActiveHashcash.bits = 18 # Moderate difficulty - balances security with user experience
ActiveHashcash.resource = nil # Use request.host (default)

# Configure the base controller class for the dashboard
Rails.application.configure do
  ActiveHashcash.base_controller_class = "ApplicationController"
end

# Set up logging and monitoring for hashcash events
ActiveSupport::Notifications.subscribe("active_hashcash.stamp_created") do |*_args, data|
  Rails.logger.info "[HASHCASH] Valid stamp created - " \
                    "IP: #{data[:ip_address]}, " \
                    "Path: #{data[:request_path]}, " \
                    "Bits: #{data[:bits]}"
end

ActiveSupport::Notifications.subscribe("active_hashcash.stamp_rejected") do |*_args, data|
  Rails.logger.warn "[HASHCASH] Invalid stamp rejected - " \
                     "IP: #{data[:ip_address]}, " \
                     "Path: #{data[:request_path]}, " \
                     "Reason: #{data[:reason]}"
end
