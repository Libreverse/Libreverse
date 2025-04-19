# frozen_string_literal: true

class RodauthController < ApplicationController
  # Used by Rodauth for rendering views, CSRF protection, running any
  # registered action callbacks and rescue handlers, instrumentation etc.

  # Controller callbacks and rescue handlers will run around Rodauth endpoints.
  # before_action :verify_captcha, only: :login, if: -> { request.post? }
  # rescue_from("SomeError") { |exception| ... }

  # Layout can be changed for all Rodauth pages or only certain pages.
  # layout "authentication"
  # layout -> do
  #   case rodauth.current_route
  #   when :login, :create_account, :verify_account, :verify_account_resend,
  #        :reset_password, :reset_password_request
  #     "authentication"
  #   else
  #     "application"
  #   end
  # end

  before_action :log_rodauth_action
  before_action :set_request

  # Add after_action to handle redirects for Turbo Stream logins
  # Target the :login action, as this is how Rails identifies the action for the /login route
  # after_action :handle_login_redirect, only: :login, if: -> { request.post? }

  def log_rodauth_action
    Rails.logger.info "DEBUG: [RodauthController] Action #{action_name} triggered for route: #{rodauth.current_route}, method: #{request.request_method}"
    # Removed secret_key_base hash logging to avoid leaking derived secrets
  end

  private

  def set_request
    @request = request
  end

=begin
  def handle_login_redirect
    # Only proceed if login was successful and it was a Turbo Stream request
    return unless rodauth.logged_in?
    return unless request.format.turbo_stream?
    # Also, don't interfere if Rodauth/Roda already set a redirect response (e.g., for pwned password)
    return if response.redirect?

    target_path = rodauth.login_redirect
    Rails.logger.info "[RodauthController] Successful login (Turbo Stream), redirecting via 303 to: #{target_path}"
    redirect_to target_path, status: :see_other
  end
=end
end
