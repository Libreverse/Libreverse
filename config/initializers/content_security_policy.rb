# the following is from my personal website codebase
# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

# csp disabled for now

=begin

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https
    policy.img_src     :self, :https
    policy.object_src  :none
    policy.script_src  :self, :https
    # Allow @vite/client to hot reload javascript changes in development
#    policy.script_src *policy.script_src, :unsafe_eval, "http://#{ ViteRuby.config.host_with_port }" if Rails.env.development?

    # You may need to enable this in production as well depending on your setup.
#    policy.script_src *policy.script_src, :blob if Rails.env.test?

    # Hash for Turbo's progress bar style to allow it
    policy.style_src   :self, :https, "'sha256-WAyOw4V+FqDc35lQPyRADLBWbuNK8ahvYEaQIYF1+Ps='"
    # Allow @vite/client to hot reload style changes in development
#    policy.style_src *policy.style_src, :unsafe_inline if Rails.env.development?


    # If you're using WebSockets or similar:
    # policy.connect_src :self, :https, 'ws://localhost:3000' if Rails.env.development?
    # Allow @vite/client to hot reload changes in development
#    policy.connect_src *policy.connect_src, "ws://#{ ViteRuby.config.host_with_port }" if Rails.env.development?

  end

  # Generate session nonces for permitted scripts and styles
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w(script-src style-src)

  # Enforce the policy, do not just report
  config.content_security_policy_report_only = false
end

=end
