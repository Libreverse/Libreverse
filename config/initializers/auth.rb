# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# Rodauth Base Configuration
Rodauth::Rails.configure do |config|
  config.app = "RodauthApp"
end

# OmniAuth Configuration for Federated Authentication

require "omniauth"
require "omniauth_openid_connect"

# Configure OmniAuth middleware with dynamic provider support
Rails.application.config.middleware.use OmniAuth::Builder do
  # Dynamic OpenID Connect provider that gets configured per request
  provider :openid_connect,
           name: :federated,
           setup: lambda { |env|
             request = Rack::Request.new(env)
             session = request.session

             # Only proceed if we have the necessary session data
             if session[:oidc_domain] && session[:client_id] && session[:client_secret]
               strategy = env["omniauth.strategy"]

               # Configure the strategy with session data
               strategy.options.merge!(
                 issuer: "https://#{session[:oidc_domain]}",
                 discovery: true,
                 client_id: session[:client_id],
                 client_secret: session[:client_secret],
                 scope: %w[openid profile email],
                 response_type: "code",
                 redirect_uri: "https://#{LibreverseInstance::Application.instance_domain}/auth/federated/callback"
               )
             else
               # If we don't have session data, this will cause the auth to fail
               # which is what we want - the user should go through the proper flow
               Rails.logger.warn "Federated auth attempted without proper session setup"
             end
           }
end

# Configure OmniAuth failure handling
OmniAuth.config.on_failure = proc do |env|
  message_key = env["omniauth.error"] || env["omniauth.error.type"] || "unknown"
  Rails.logger.error "OmniAuth failure: #{message_key}"

  # Clear any federated auth session data
  request = Rack::Request.new(env)
  session = request.session
  session.delete(:client_id)
  session.delete(:client_secret)
  session.delete(:oidc_domain)
  session.delete(:federated_username)
  session.delete(:federated_identifier)

  # Redirect to login with error
  [ 302, { "Location" => "/login?error=federation_failed" }, [] ]
end
