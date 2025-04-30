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

    # Add nonce only for production/staging builds
    script_sources << -> { "'nonce-#{SecureRandom.base64(16)}'" } if Rails.env.production?

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
    policy.connect_src(*policy.connect_src, "ws:")

    # Iframes for Experience viewer (data‑URI) remain allowed.
    policy.frame_src   :self, :data

    # WebSocket & API connections
    policy.connect_src :self, :https, "wss://*.libreverse.dev", "wss://*.geor.me", :data, "ws:"

    # Test allowances – blob URIs used by rails system tests
    policy.script_src(*policy.script_src, :blob) if Rails.env.test?

    # Report CSP violations (Report‑Only first, then enforce)
    policy.report_uri "/csp-report"
  end

  # Initially run in report‑only mode; switch to false after verifying
  config.content_security_policy_report_only = false
end
