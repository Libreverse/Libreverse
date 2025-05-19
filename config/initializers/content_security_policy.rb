# frozen_string_literal: true

# Content Security Policy Configuration
Rails.application.configure do
  config.content_security_policy do |policy|
    # Base directives
    policy.default_src :self
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, :blob
    policy.object_src  :none

    # ---- Dynamic script/style directives ----
    script_sources = %i[self https unsafe_inline data blob]
    style_sources  = %i[self https unsafe_inline data]

    # Removed nonce requirement to allow inline scripts/styles since our app inlines large Vite bundles.

    policy.script_src(*script_sources)
    policy.style_src(*style_sources)
    policy.worker_src :self, :blob

    # Dev-only extra allowances (eval + websocket)
    if Rails.env.development?
      policy.script_src(*policy.script_src, :unsafe_eval)
      policy.connect_src(*policy.connect_src, "ws://#{ViteRuby.config.host_with_port}")
      policy.worker_src(*policy.worker_src, :unsafe_eval)
    end

    # Allow generic WebSocket scheme (ws:) so localhost or custom ports work when not using SSL
    policy.connect_src(*policy.connect_src, :self, :https, :data, "ws:")

    # Iframes for Experience viewer (data-URI) remain allowed.
    policy.frame_src :self, :data

    # Test allowances – blob URIs used by rails system tests
    policy.script_src(*policy.script_src, :blob) if Rails.env.test?

    # Report CSP violations (Report‑Only first, then enforce)
    policy.report_uri "/csp-report"
  end

  # Configure a default Permissions-Policy (removing browsing-topics if it was added by default)
  config.permissions_policy do |policy|
    policy.accelerometer :none
    policy.autoplay :self
    policy.camera :none
    policy.display_capture :none
    policy.encrypted_media :self
    policy.fullscreen :self
    policy.geolocation :none
    policy.gyroscope :none
    policy.magnetometer :none
    policy.microphone :none
    policy.midi :none
    policy.payment :none
    policy.picture_in_picture :self
    policy.screen_wake_lock :none
    policy.sync_xhr :self
    policy.usb :none
  end

  # Initially ran in report‑only mode; switched to false after verifying
  config.content_security_policy_report_only = false
end
