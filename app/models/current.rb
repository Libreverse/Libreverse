# frozen_string_literal: true
# shareable_constant_value: literal

# Provides thread-isolated attributes for storing global request data,
# such as the current account.
# See: https://api.rubyonrails.org/classes/ActiveSupport/CurrentAttributes.html
class Current < ActiveSupport::CurrentAttributes
  # Define attributes that can be set per request
  attribute :account, :ip, :real_ip
  # Add other attributes here as needed, e.g.:
  # attribute :request_id, :user_agent, :ip_address
end
