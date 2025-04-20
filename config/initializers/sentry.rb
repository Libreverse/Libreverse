# frozen_string_literal: true

# Sentry Error Tracking Configuration
Sentry.init do |config|
  config.dsn =
    "https://3ff68d31dcdf415b8904a05b75fdc7b1@glitchtip-cs40w800ggw0gs0k804skcc0.geor.me/7"
  config.breadcrumbs_logger = %i[active_support_logger http_logger]

  # Strip IP address PII
  config.before_send = lambda do |event, _hint|
    if (ip = event.dig(:user, :ip_address))
      event[:user][:ip_address] = IpAnonymizer.anonymise_ip(ip)
    end
    event
  end
end
