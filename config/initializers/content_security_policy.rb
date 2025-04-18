# frozen_string_literal: true

# Content Security Policy Configuration
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, :blob
    policy.object_src  :none

    # Base policies
    policy.script_src  :self, :https, :unsafe_inline, :data
    policy.style_src   :self, :https, :unsafe_inline
    policy.frame_src   :self, :data
    policy.connect_src :self, :https, "wss://*.libreverse.dev", "wss://*.geor.me", :data

    # Development allowances
    if Rails.env.development?
      policy.script_src(*policy.script_src, :unsafe_eval, "http://#{ViteRuby.config.host_with_port}")
      policy.connect_src(*policy.connect_src, "ws://#{ViteRuby.config.host_with_port}")
    end

    # Test allowances
    policy.script_src(*policy.script_src, :blob) if Rails.env.test?
  end

  # Report only or enforce
  config.content_security_policy_report_only = false
end
