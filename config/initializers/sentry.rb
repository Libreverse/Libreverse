# frozen_string_literal: true

# Allow‑list of benign headers we want to keep (everything else removed)
SAFE_HEADERS = %w[User-Agent Referer].freeze

# Sentry Error Tracking Configuration
Sentry.init do |config|
  # Project DSN (environment‑specific value ideally fetched via ENV)
  config.dsn =
    "https://3ff68d31dcdf415b8904a05b75fdc7b1@glitchtip-cs40w800ggw0gs0k804skcc0.geor.me/7"

  # Collect breadcrumbs from Rails & HTTP libraries
  config.breadcrumbs_logger = %i[active_support_logger http_logger]

  # ──────────────────────────────────────────────────────────────
  # 🚫  Privacy: never send PII to Sentry
  # ──────────────────────────────────────────────────────────────
  # Turns off automatic inclusion of user, cookies and IP address
  config.send_default_pii = false

  # custom scrubber – runs for every event before it is sent
  config.before_send = lambda do |event, _hint|
    # 1. User anonymisation
    if event.user.present?
      anon_id = event.user[:id]
      event.user = { id: anon_id } if anon_id.present?
    end

    # 2. Request scrubbing
    if event.request
      # Keep only allow‑listed headers
      event.request.headers.select! { |k, _| SAFE_HEADERS.include?(k) } if event.request.headers

      # Remove cookies, query strings and raw body which may contain PII
      event.request.data&.except!(:cookies, :query_string, :body)
    end

    # 3. IP anonymisation (belt‑and‑braces)
    if (ip = event.dig(:user, :ip_address))
      event[:user][:ip_address] = IpAnonymizer.anonymise_ip(ip)
    end

    event
  end
end
