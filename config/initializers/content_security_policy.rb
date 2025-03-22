# the following is from my personal website codebase
# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :https
    policy.style_src   :self, :https

    # Allow inline scripts and styles with nonces
    policy.script_src :self, :https, :unsafe_inline
    policy.style_src :self, :https, :unsafe_inline

    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"

    # Allow @vite/client to hot reload javascript changes in development
    policy.script_src(*policy.script_src, :unsafe_eval, "http://#{ViteRuby.config.host_with_port}") if Rails.env.development?

    # You may need to enable this in production as well depending on your setup.
    policy.script_src(*policy.script_src, :blob) if Rails.env.test?

    # Hash for Turbo's progress bar style to allow it
    policy.style_src :self, :https, "'sha256-WAyOw4V+FqDc35lQPyRADLBWbuNK8ahvYEaQIYF1+Ps='"
    # Allow @vite/client to hot reload style changes in development
    policy.style_src(*policy.style_src, :unsafe_inline) if Rails.env.development?

    # If you're using WebSockets or similar:
    policy.connect_src :self, :https, "wss://*.libreverse.dev", "wss://*.geor.me"
    # Allow @vite/client to hot reload changes in development
    policy.connect_src(*policy.connect_src, "ws://#{ViteRuby.config.host_with_port}") if Rails.env.development?
  end

  # Generate session nonces for permitted scripts and styles
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src style-src]

  # Enforce the policy, do not just report
  config.content_security_policy_report_only = false
end
