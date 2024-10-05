# the following is from my personal website codebase
# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https
    policy.img_src     :self, :https
    policy.object_src  :none
    policy.script_src  :self, :https
    # Hash for Turbo's progress bar style to allow it
    policy.style_src   :self, :https, "'sha256-WAyOw4V+FqDc35lQPyRADLBWbuNK8ahvYEaQIYF1+Ps='"
    
    # If you're using WebSockets or similar:
    # policy.connect_src :self, :https, 'ws://localhost:3000' if Rails.env.development?
  end

  # Generate session nonces for permitted scripts and styles
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w(script-src style-src)

  # Enforce the policy, do not just report
  config.content_security_policy_report_only = false
end
