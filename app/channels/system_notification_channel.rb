# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class SystemNotificationChannel < ApplicationCable::Channel
  def subscribed
    # Subscribe to system notifications for this connection
    stream_from "system_notifications_#{connection.current_account_id}"
    Rails.logger.debug "[SystemNotificationChannel] Subscribed connection #{connection.current_account_id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed.
    Rails.logger.debug "[SystemNotificationChannel] Unsubscribed connection #{connection.current_account_id}"
  end
end
